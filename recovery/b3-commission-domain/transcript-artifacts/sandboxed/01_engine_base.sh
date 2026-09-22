cat > app/services/commissionEngine.js <<'ENGINE'
// ============================================================================
// COMMISSION ENGINE — B3.5
//
// Calcula a comissão do agente de vendas a partir do SNAPSHOT de faixas
// congelado no contrato:
//
//   SalesAgent.defaultCommissionPlanId
//     → CommissionPlan (+ CommissionPlanTier)
//       → SalesAgentCommission        (contrato, criado no 1º pagamento)
//         → SalesAgentCommissionTerm  (cópia imutável das faixas)
//           → SalesAgentCommissionInstallment (lançamento por faixa atravessada)
//
// O percentual NÃO vem mais de `agent.commissionPercent`. Depois que o
// contrato é fechado, o cálculo lê SOMENTE os `terms` — mexer no plano não
// muda contrato já fechado.
//
// Campos aposentados, NUNCA usados como fonte de cálculo:
//   commissionPercent, commissionMonths, percent, endDate,
//   totalInstallments, paidInstallments
//
// Fora de escopo neste ciclo (ver relatório B3.5):
//   PAYMENT_REFUNDED / reversal, payout, contratos override (pai/filho),
//   tierBasis 'volume', corte por hardEndDate.
// ============================================================================

const { fn, col } = require('sequelize');
const { format } = require('date-fns');
const logger = require('../utils/logger');

const BILLING_CYCLE_UNITS = { monthly: 1, quarterly: 3, annual: 12 };

/**
 * Erro de comissão com contexto anexado. O caller (webhook do Asaas) decide a
 * política — o engine nunca engole o erro em silêncio.
 */
class CommissionEngineError extends Error {
  constructor(message, context = {}) {
    super(message);
    this.name = 'CommissionEngineError';
    this.context = context;
  }
}

// ---------------------------------------------------------------------------
// Datas
// ---------------------------------------------------------------------------

// 'YYYY-MM-DD' vindo do Asaas precisa virar data LOCAL, senão `new Date()` o lê
// como UTC meia-noite e, em UTC-3, o referenceMonth cai no mês anterior.
function toDate(value, context) {
  if (value instanceof Date) {
    if (Number.isNaN(value.getTime())) {
      throw new CommissionEngineError('paymentDate inválida', context);
    }
    return value;
  }

  if (typeof value === 'string') {
    const dateOnly = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
    if (dateOnly) {
      return new Date(Number(dateOnly[1]), Number(dateOnly[2]) - 1, Number(dateOnly[3]));
    }
  }

  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    throw new CommissionEngineError('paymentDate inválida', context);
  }
  return parsed;
}

// ---------------------------------------------------------------------------
// Dinheiro — tudo em centavos inteiros, nunca em float
// ---------------------------------------------------------------------------

function toCents(value, context) {
  const n = typeof value === 'number' ? value : parseFloat(String(value));
  if (!Number.isFinite(n)) {
    throw new CommissionEngineError(`valor do pagamento inválido: ${value}`, context);
  }
  if (n < 0) {
    throw new CommissionEngineError(`valor do pagamento negativo: ${value}`, context);
  }
  return Math.round(n * 100);
}

function centsToAmount(cents) {
  return (cents / 100).toFixed(2);
}

// Percentual guardado como DECIMAL(5,2) → basis points inteiros (40.00 → 4000).
function percentToBasisPoints(percent, context) {
  const n = parseFloat(String(percent));
  if (!Number.isFinite(n)) {
    throw new CommissionEngineError(`percentual de faixa inválido: ${percent}`, context);
  }
  return Math.round(n * 100);
}

// amount = base * percent / 100, com arredondamento half-up no centavo.
function applyPercent(baseCents, basisPoints) {
  return Math.round((baseCents * basisPoints) / 10000);
}

// ---------------------------------------------------------------------------
// Faixas
// ---------------------------------------------------------------------------

/**
 * Interseção entre o intervalo de unidades do pagamento e cada faixa do
 * contrato. `toUnit` NULL = faixa aberta (infinita).
 *
 * A faixa é escolhida pelo intervalo de unidades, NUNCA por installmentNumber.
 */
function buildSegments(terms, paymentFrom, paymentTo) {
  const segments = [];

  for (const term of terms) {
    const termTo = term.toUnit === null || term.toUnit === undefined
      ? Number.POSITIVE_INFINITY
      : term.toUnit;

    const segmentFrom = Math.max(paymentFrom, term.fromUnit);
    const segmentTo = Math.min(paymentTo, termTo);

    if (segmentFrom <= segmentTo) {
      segments.push({
        term,
        unitFrom: segmentFrom,
        unitTo: segmentTo,
        unitsCovered: segmentTo - segmentFrom + 1,
      });
    }
  }

  return segments;
}

/**
 * Rateia o valor do pagamento entre os segmentos.
 *
 *   baseAmount = value * unitsCovered / unitsThisPayment
 *
 * O total rateado é calculado UMA vez sobre as unidades comissionáveis; o
 * resíduo de centavos cai, de forma determinística, no ÚLTIMO segmento.
 */
function allocateBases(segments, paymentValueCents, unitsThisPayment) {
  const commissionableUnits = segments.reduce((acc, s) => acc + s.unitsCovered, 0);
  const totalBaseCents = Math.round((paymentValueCents * commissionableUnits) / unitsThisPayment);

  let allocated = 0;

  return segments.map((segment, index) => {
    const isLast = index === segments.length - 1;

    const baseCents = isLast
      ? totalBaseCents - allocated
      : Math.round((paymentValueCents * segment.unitsCovered) / unitsThisPayment);

    allocated += baseCents;

    return { ...segment, baseCents };
  });
}

// ---------------------------------------------------------------------------
// Engine
// ---------------------------------------------------------------------------

function buildEngine(models) {
  const {
    SalesAgent,
    SalesAgentCommission,
    SalesAgentCommissionTerm,
    SalesAgentCommissionInstallment,
    CommissionPlan,
    Signature,
    Tenant,
  } = models;

  function isUniqueViolation(error) {
    return error && error.name === 'SequelizeUniqueConstraintError';
  }

  /**
   * consumedUnits é DERIVADO dos lançamentos, nunca de um contador mutável:
   *
   *   SUM(credit.unitsCovered) - SUM(reversal.unitsCovered)
   *
   * Lançamentos legados têm unitsCovered NULL e simplesmente não somam.
   */
  async function consumedUnitsFor(salesAgentCommissionId, transaction) {
    const rows = await SalesAgentCommissionInstallment.findAll({
      attributes: [
        'entryType',
        [fn('COALESCE', fn('SUM', col('unitsCovered')), 0), 'units'],
      ],
      where: { salesAgentCommissionId },
      group: ['entryType'],
      raw: true,
      transaction,
    });

    let credit = 0;
    let reversal = 0;

    for (const row of rows) {
      const units = Number(row.units) || 0;
      if (row.entryType === 'credit') credit = units;
      if (row.entryType === 'reversal') reversal = units;
    }

    return credit - reversal;
  }

  // Ordinal informativo. Derivado do que já existe no contrato — nunca de
  // paidInstallments, que está aposentado.
  async function nextInstallmentNumber(salesAgentCommissionId, transaction) {
    const max = await SalesAgentCommissionInstallment.max('installmentNumber', {
      where: { salesAgentCommissionId },
      transaction,
    });

    const current = Number(max);
    return (Number.isFinite(current) ? current : 0) + 1;
  }

  async function findDirectContract({ agentId, tenantId, signatureId }, transaction, lock = false) {
    return SalesAgentCommission.findOne({
      where: {
        salesAgentId: agentId,
        tenantId,
        signatureId,
        kind: 'direct',
      },
      transaction,
      ...(lock && transaction ? { lock: true } : {}),
    });
  }

  /**
   * Fecha o contrato direto copiando o plano padrão do agente. O snapshot
   * (basis / tierBasis / totalUnits / terms) congela aqui — commissionPlanId
   * fica só como rastro da origem.
   */
  async function createDirectContract({ agent, tenant, signature, context }, transaction) {
    const plan = await CommissionPlan.findByPk(agent.defaultCommissionPlanId, {
      include: [{ association: 'tiers' }],
      transaction,
    });

    if (!plan) {
      throw new CommissionEngineError(
        `defaultCommissionPlanId ${agent.defaultCommissionPlanId} não encontrado em commission_plans`,
        context,
      );
    }

    const tiers = [...(plan.tiers || [])].sort((a, b) => a.tierOrder - b.tierOrder);

    if (tiers.length === 0) {
      throw new CommissionEngineError(
        `CommissionPlan ${plan.id} não tem faixas — contrato não pode ser fechado`,
        context,
      );
    }

    const payload = {
      salesAgentId: agent.id,
      tenantId: tenant.id,
      signatureId: signature.id,
      kind: 'direct',
      status: 'active',
      commissionPlanId: plan.id,
      basis: plan.basis,
      tierBasis: plan.tierBasis,
      totalUnits: plan.totalUnits,
      startDate: signature.start || format(context.paymentDateObj, 'yyyy-MM-dd'),
      terms: tiers.map((t) => ({
        tierOrder: t.tierOrder,
        fromUnit: t.fromUnit,
        toUnit: t.toUnit,
        percent: t.percent,
      })),
    };

    try {
      return await SalesAgentCommission.create(payload, {
        include: [{ association: 'terms' }],
        transaction,
      });
    } catch (error) {
      // Dois webhooks simultâneos podem tentar fechar o mesmo contrato.
      // A unique (salesAgentId, tenantId, signatureId, kind) decide o vencedor;
      // o perdedor reencontra o contrato com leitura travada.
      if (!isUniqueViolation(error)) throw error;

      const existing = await findDirectContract(
        { agentId: agent.id, tenantId: tenant.id, signatureId: signature.id },
        transaction,
        true,
      );

      if (existing) {
        logger.warn('[commission] corrida ao fechar contrato — reusando o existente', {
          ...context,
          salesAgentCommissionId: existing.id,
        });
        return existing;
      }

      throw error;
    }
  }

  // Quantas unidades esse pagamento consome.
  function unitsForPayment({ contract, signature, context }) {
    if (contract.basis === 'payment') return 1;

    if (contract.basis !== 'billing_month') {
      throw new CommissionEngineError(`basis não suportado: ${contract.basis}`, context);
    }

    // billing_month: usa o helper do próprio Signature. Sem ciclo determinado
    // ABORTAMOS — assumir 1 em silêncio comissionaria um anual como mensal.
    if (!signature.billingCycle || !(signature.billingCycle in BILLING_CYCLE_UNITS)) {
      throw new CommissionEngineError(
        `billingCycle indeterminado na signature ${signature.id} — comissão abortada`,
        context,
      );
    }

    const months = signature.billingCycleMonths();

    if (!Number.isInteger(months) || months < 1) {
      throw new CommissionEngineError(
        `billingCycleMonths() retornou valor inválido (${months}) para a signature ${signature.id}`,
        context,
      );
    }

    return months;
  }

  /**
   * Assinatura pública — preservada exatamente. O caller do Asaas não muda.
   *
   * @param {string} subscriptionId asaasId da Signature
   * @param {number|string} value   valor efetivamente pago pelo tenant
   * @param {Date|string} paymentDate
   * @param {string} paymentId      payment.id do Asaas
   * @param {import('sequelize').Transaction} transaction
   */
  async function processCommissionFromPayment(
    subscriptionId,
    value,
    paymentDate,
    paymentId,
    transaction,
  ) {
    if (!subscriptionId || !paymentId) return;

    const context = { subscriptionId, paymentId };

    try {
      // ---------------------------------------------------------------------
      // 1. Resolução: signature → tenant → agente
      // ---------------------------------------------------------------------
      const signature = await Signature.findOne({
        where: { asaasId: subscriptionId },
        transaction,
      });

      if (!signature) return;

      const tenant = await Tenant.findByPk(signature.tenantId, { transaction });
      if (!tenant?.salesAgentId) return;

      context.tenantId = tenant.id;

      const agent = await SalesAgent.findByPk(tenant.salesAgentId, { transaction });
      if (!agent) return;

      context.salesAgentId = agent.id;
      context.paymentDateObj = toDate(paymentDate, context);

      // ---------------------------------------------------------------------
      // 2. Contrato — reusa o existente, senão fecha a partir do plano padrão
      // ---------------------------------------------------------------------
      let contract = await findDirectContract(
        { agentId: agent.id, tenantId: tenant.id, signatureId: signature.id },
        transaction,
      );

      if (!contract) {
        if (!agent.defaultCommissionPlanId) {
          logger.warn(
            '[commission] agente sem defaultCommissionPlanId — nenhuma comissão gerada',
            { ...context, paymentDateObj: undefined },
          );
          return;
        }

        contract = await createDirectContract({ agent, tenant, signature, context }, transaction);
      }

      context.salesAgentCommissionId = contract.id;

      if (contract.status === 'cancelled' || contract.status === 'suspended') {
        logger.warn(
          `[commission] contrato ${contract.status} — nenhuma comissão gerada`,
          { ...context, paymentDateObj: undefined },
        );
        return;
      }

      if (contract.tierBasis !== 'sequence') {
        throw new CommissionEngineError(
          `tierBasis '${contract.tierBasis}' não implementado neste ciclo`,
          context,
        );
      }

      // ---------------------------------------------------------------------
      // 3. Idempotência por CONTRATO + pagamento (nunca paymentId global:
      //    direct e override dividirão o mesmo pagamento no futuro)
      // ---------------------------------------------------------------------
      const alreadyProcessed = await SalesAgentCommissionInstallment.findOne({
        where: {
          salesAgentCommissionId: contract.id,
          paymentId,
          entryType: 'credit',
        },
        transaction,
      });

      if (alreadyProcessed) {
        logger.info('[commission] pagamento já processado nesse contrato — ignorando', {
          ...context,
          paymentDateObj: undefined,
        });
        return;
      }

      // ---------------------------------------------------------------------
      // 4. Unidades do pagamento e do contrato
      // ---------------------------------------------------------------------
      const unitsThisPayment = unitsForPayment({ contract, signature, context });
      const consumedUnits = await consumedUnitsFor(contract.id, transaction);

      let unitsToApply = unitsThisPayment;

      if (contract.totalUnits !== null && contract.totalUnits !== undefined) {
        const remaining = contract.totalUnits - consumedUnits;

        if (remaining <= 0) {
          if (contract.status !== 'completed') {
            await contract.update({ status: 'completed' }, { transaction });
          }
          logger.info('[commission] contrato esgotado — nenhuma comissão gerada', {
            ...context,
            paymentDateObj: undefined,
            totalUnits: contract.totalUnits,
            consumedUnits,
          });
          return;
        }

        // Pagamento que ultrapassa o limite comissiona só até o limite.
        unitsToApply = Math.min(unitsThisPayment, remaining);
      }

      // ---------------------------------------------------------------------
      // 5. Faixas atravessadas por esse pagamento
      // ---------------------------------------------------------------------
      const terms = await SalesAgentCommissionTerm.findAll({
        where: { salesAgentCommissionId: contract.id },
        order: [['tierOrder', 'ASC']],
        transaction,
      });

      if (terms.length === 0) {
        throw new CommissionEngineError(
          `contrato ${contract.id} sem terms — snapshot de faixas ausente`,
          context,
        );
      }

      const paymentFrom = consumedUnits + 1;
      const paymentTo = consumedUnits + unitsToApply;

      const segments = allocateBases(
        buildSegments(terms, paymentFrom, paymentTo),
        toCents(value, context),
        unitsThisPayment,
      );

      if (segments.length === 0) {
        logger.warn('[commission] nenhuma faixa cobre o intervalo do pagamento', {
          ...context,
          paymentDateObj: undefined,
          paymentFrom,
          paymentTo,
        });
        return;
      }

      // ---------------------------------------------------------------------
      // 6. Lançamentos — uma linha por faixa atravessada
      // ---------------------------------------------------------------------
      const paymentDateObj = context.paymentDateObj;
      const referenceMonth = format(paymentDateObj, 'yyyy-MM');
      const baseInstallmentNumber = await nextInstallmentNumber(contract.id, transaction);

      for (let index = 0; index < segments.length; index += 1) {
        const segment = segments[index];
        const basisPoints = percentToBasisPoints(segment.term.percent, context);

        try {
          await SalesAgentCommissionInstallment.create(
            {
              salesAgentCommissionId: contract.id,
              termId: segment.term.id,
              paymentId,
              paymentDate: paymentDateObj,
              billingCycle: signature.billingCycle,
              unitFrom: segment.unitFrom,
              unitTo: segment.unitTo,
              unitsCovered: segment.unitsCovered,
              baseAmount: centsToAmount(segment.baseCents),
              percentApplied: segment.term.percent,
              amount: centsToAmount(applyPercent(segment.baseCents, basisPoints)),
              installmentNumber: baseInstallmentNumber + index,
              referenceMonth,
              entryType: 'credit',
              status: 'pending',
              // LEGADO: `dueDate` é NOT NULL e nenhuma migration pode mudar isso
              // neste ciclo. Deixou de significar "data do pagamento do tenant"
              // (que agora é `paymentDate`) e ainda não significa repasse (que
              // será `payoutDueDate`). Preenchido só para satisfazer a coluna.
              dueDate: format(paymentDateObj, 'yyyy-MM-dd'),
            },
            { transaction },
          );
        } catch (error) {
          // Corrida: o concorrente já gravou esse pagamento. Se a colisão
          // acontece no PRIMEIRO segmento, nada nosso foi escrito e tratamos
          // como idempotência. Depois disso o estado é parcial e precisa
          // subir para o caller.
          if (isUniqueViolation(error) && index === 0) {
            logger.warn('[commission] corrida no lançamento — pagamento já creditado', {
              ...context,
              paymentDateObj: undefined,
            });
            return;
          }
          throw error;
        }
      }

      // ---------------------------------------------------------------------
      // 7. Status do contrato
      // ---------------------------------------------------------------------
      const consumedAfter = consumedUnits + unitsToApply;
      const completed =
        contract.totalUnits !== null &&
        contract.totalUnits !== undefined &&
        consumedAfter >= contract.totalUnits;

      const nextStatus = completed ? 'completed' : 'active';

      if (contract.status !== nextStatus) {
        await contract.update({ status: nextStatus }, { transaction });
      }

      logger.info('[commission] comissão lançada', {
        ...context,
        paymentDateObj: undefined,
        segments: segments.length,
        unitsToApply,
        consumedAfter,
        status: nextStatus,
      });
    } catch (error) {
      // Nada de `catch → return` silencioso: comissão errada precisa aparecer.
      logger.error('[commission] falha ao processar comissão', {
        subscriptionId,
        paymentId,
        tenantId: context.tenantId,
        salesAgentId: context.salesAgentId,
        salesAgentCommissionId: context.salesAgentCommissionId,
        error: error.message,
      });
      throw error;
    }
  }

  return { processCommissionFromPayment };
}

// Engine padrão, amarrado ao registry de models da aplicação.
// O require é preguiçoso para que o módulo possa ser carregado em teste sem
// subir a conexão de app/models/index.js.
let defaultEngine = null;

function processCommissionFromPayment(
  subscriptionId,
  value,
  paymentDate,
  paymentId,
  transaction,
) {
  if (!defaultEngine) {
    defaultEngine = buildEngine(require('../models'));
  }

  return defaultEngine.processCommissionFromPayment(
    subscriptionId,
    value,
    paymentDate,
    paymentId,
    transaction,
  );
}

module.exports = {
  processCommissionFromPayment,
  buildEngine,
  CommissionEngineError,
  // exportados para teste do cálculo puro
  buildSegments,
  allocateBases,
};
ENGINE
node -e "require('./app/services/commissionEngine.js'); console.log('OK sintaxe')"