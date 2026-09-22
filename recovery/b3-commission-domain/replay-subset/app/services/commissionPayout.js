// ============================================================================
// COMMISSION PAYOUT — B3.7 (aprovação e pagamento de lançamentos)
//
// Este serviço NÃO calcula comissão. Ele só muda o ESTADO FINANCEIRO de
// lançamentos que o `commissionEngine` já gravou:
//
//     pending ──approveInstallments──▶ approved ──payApprovedInstallments──▶ paid
//        │                                │
//        └────────cancelReversedInstallments───────▶ cancelled
//
// Nenhuma outra transição existe. Em particular NÃO há:
//   pending → paid, paid → approved, paid → pending, approved → pending,
//   cancelled → qualquer coisa, paid → cancelled.
//
// O valor repassado vem SEMPRE de `installment.amount`, congelado pelo engine
// no momento do crédito. Percentual, faixa, base, unidades, plano e contrato
// NUNCA são relidos aqui — o contrato histórico é soberano, e mexer no plano
// depois não muda um centavo de um lançamento já gravado.
//
// Fora de escopo neste ciclo:
//   integração bancária/PIX (o commissionJob de B3.8 orquestra este service,
//   mas a liquidação externa continua fora daqui), workflow de
//   cancelamento/ajuste, débito automático de comissão já paga,
//   frontend, tabela própria de payout.
// ============================================================================

const crypto = require('crypto');
const { format } = require('date-fns');
const logger = require('../utils/logger');

/**
 * Erro de payout com contexto anexado. Mesma política do engine: o serviço
 * nunca engole o erro, e o caller é dono da transaction (logo, do rollback).
 */
class CommissionPayoutError extends Error {
  constructor(message, context = {}) {
    super(message);
    this.name = 'CommissionPayoutError';
    this.context = context;
  }
}

// ---------------------------------------------------------------------------
// Dinheiro — centavos inteiros, nunca float solto
// ---------------------------------------------------------------------------

function toCents(value, context) {
  const n = typeof value === 'number' ? value : parseFloat(String(value));
  if (!Number.isFinite(n)) {
    throw new CommissionPayoutError(`valor de lançamento inválido: ${value}`, context);
  }
  return Math.round(n * 100);
}

function centsToAmount(cents) {
  return (cents / 100).toFixed(2);
}

// ---------------------------------------------------------------------------
// payoutBatchId
// ---------------------------------------------------------------------------

// Formato: PB-<yyyyMMdd>-<12 hex>  →  "PB-20260922-9f3c1a7d5e2b" (24 chars).
//
// Legível na conciliação (o prefixo diz o que é, a data diz quando o lote
// fechou) e único sem depender do banco: os 48 bits aleatórios tornam colisão
// dentro do mesmo dia irrelevante. Cabe folgado no STRING(255) da coluna.
function generatePayoutBatchId(now = new Date()) {
  return `PB-${format(now, 'yyyyMMdd')}-${crypto.randomBytes(6).toString('hex')}`;
}

function buildPayout(models) {
  const { SalesAgentCommission, SalesAgentCommissionInstallment } = models;

  // -------------------------------------------------------------------------
  // Leitura com lock
  // -------------------------------------------------------------------------

  /**
   * Relê os lançamentos DENTRO da transaction, com SELECT ... FOR UPDATE.
   *
   * Ordena por id para que dois lotes com interseção peguem as linhas sempre
   * na mesma ordem — sem isso, dois processos se cruzariam em deadlock em vez
   * de um esperar o outro.
   */
  async function lockInstallments(installmentIds, transaction) {
    return SalesAgentCommissionInstallment.findAll({
      where: { id: installmentIds },
      order: [['id', 'ASC']],
      lock: transaction.LOCK.UPDATE,
      transaction,
    });
  }

  /**
   * Estornos que apontam para os créditos informados.
   *
   * Reversal é append-only: não existe "saldo" mutável em lugar nenhum. O
   * quanto de um crédito ainda vale é DERIVADO daqui, somando os lançamentos.
   */
  async function reversalsOf(creditIds, transaction) {
    if (creditIds.length === 0) return new Map();

    const reversals = await SalesAgentCommissionInstallment.findAll({
      where: { reversalOfId: creditIds, entryType: 'reversal' },
      attributes: ['id', 'reversalOfId', 'amount'],
      transaction,
    });

    const byCredit = new Map();
    for (const reversal of reversals) {
      const list = byCredit.get(reversal.reversalOfId) || [];
      list.push(reversal);
      byCredit.set(reversal.reversalOfId, list);
    }
    return byCredit;
  }

  /**
   * Valor líquido de um crédito, em centavos: o próprio crédito menos tudo
   * que já foi estornado contra ele (os reversals têm `amount` negativo, por
   * isso a conta é uma soma).
   *
   *   netCents = credit.amount + Σ reversal.amount
   *
   * Um crédito integralmente estornado fecha em 0 e deixa de ser pagável.
   * Estorno parcial não existe hoje (o engine espelha o crédito inteiro), mas
   * a soma já trata o caso sem precisar de regra nova.
   */
  function netCentsOf(credit, reversalsByCredit, context) {
    const reversals = reversalsByCredit.get(credit.id) || [];
    return reversals.reduce(
      (acc, reversal) => acc + toCents(reversal.amount, context),
      toCents(credit.amount, context),
    );
  }

  // -------------------------------------------------------------------------
  // Elegibilidade
  // -------------------------------------------------------------------------

  /**
   * Regras comuns a aprovar e pagar. Tudo derivado dos dados existentes —
   * nenhum campo de saldo, nenhum contador.
   *
   *   1. entryType = 'credit'  — reversal é memória contábil, nunca é repassado;
   *   2. amount > 0            — nada a pagar em lançamento zerado ou negativo;
   *   3. contrato existe e não está 'cancelled';
   *   4. líquido de estornos > 0 — crédito anulado por refund não volta à fila.
   *
   * O item 4 é o coração de B3.7: olhar só o `status` do crédito não basta.
   * Um crédito `pending`/`approved` que recebeu reversal continua com o
   * status antigo (o refund é append-only e não mexe no crédito), mas
   * economicamente já não vale nada — e não pode entrar no payout como se
   * ainda estivesse disponível.
   */
  function assertPayable(installment, { contract, netCents, context }) {
    if (installment.entryType !== 'credit') {
      throw new CommissionPayoutError(
        `lançamento ${installment.id} é '${installment.entryType}': estorno não é repassado`,
        { ...context, installmentId: installment.id },
      );
    }

    if (toCents(installment.amount, context) <= 0) {
      throw new CommissionPayoutError(
        `lançamento ${installment.id} não tem valor a repassar (amount=${installment.amount})`,
        { ...context, installmentId: installment.id },
      );
    }

    if (!contract) {
      throw new CommissionPayoutError(
        `lançamento ${installment.id} sem contrato — não há a quem repassar`,
        { ...context, installmentId: installment.id },
      );
    }

    if (contract.status === 'cancelled') {
      throw new CommissionPayoutError(
        `lançamento ${installment.id} pertence a contrato cancelado ${contract.id}`,
        { ...context, installmentId: installment.id, salesAgentCommissionId: contract.id },
      );
    }

    if (netCents <= 0) {
      throw new CommissionPayoutError(
        `lançamento ${installment.id} foi estornado — nada a repassar `
        + `(líquido ${centsToAmount(netCents)})`,
        { ...context, installmentId: installment.id },
      );
    }
  }

  /**
   * Carrega, com lock, tudo que as duas operações precisam: os lançamentos,
   * os contratos e os estornos. Garante também que todo ID pedido existe —
   * ID inválido derruba o lote inteiro, não some em silêncio.
   */
  async function loadBatch(installmentIds, transaction, context) {
    if (!Array.isArray(installmentIds) || installmentIds.length === 0) {
      throw new CommissionPayoutError('nenhum lançamento informado', context);
    }
    if (!transaction) {
      throw new CommissionPayoutError('transaction é obrigatória', context);
    }

    const ids = [...new Set(installmentIds)];
    const installments = await lockInstallments(ids, transaction);

    if (installments.length !== ids.length) {
      const found = new Set(installments.map((i) => i.id));
      const missing = ids.filter((id) => !found.has(id));
      throw new CommissionPayoutError(
        `lançamento(s) inexistente(s): ${missing.join(', ')}`,
        { ...context, missing },
      );
    }

    const contractIds = [...new Set(installments.map((i) => i.salesAgentCommissionId))];
    const contracts = await SalesAgentCommission.findAll({
      where: { id: contractIds },
      transaction,
    });
    const contractById = new Map(contracts.map((c) => [c.id, c]));

    const reversalsByCredit = await reversalsOf(ids, transaction);

    return { ids, installments, contractById, reversalsByCredit };
  }

  // -------------------------------------------------------------------------
  // 1. Aprovar — pending → approved
  // -------------------------------------------------------------------------

  /**
   * Move um lote de lançamentos de `pending` para `approved`.
   *
   * Operação atômica por construção: qualquer lançamento inelegível levanta
   * erro ANTES de qualquer UPDATE, e o rollback é do caller. Não existe lote
   * meio aprovado.
   *
   * @param {string[]} installmentIds
   * @param {import('sequelize').Transaction} transaction  obrigatória, do caller
   * @returns {Promise<{count, totalAmount, installmentIds, approvedAt}>}
   */
  async function approveInstallments(installmentIds, transaction) {
    const context = { flow: 'commission-approve' };
    const { ids, installments, contractById, reversalsByCredit } =
      await loadBatch(installmentIds, transaction, context);

    let totalCents = 0;

    for (const installment of installments) {
      // Estado relido DENTRO da transaction: o concorrente que aprovou antes
      // já commitou, e o SELECT ... FOR UPDATE enxerga o valor atual.
      if (installment.status !== 'pending') {
        throw new CommissionPayoutError(
          `lançamento ${installment.id} está '${installment.status}': `
          + "só 'pending' pode ser aprovado",
          { ...context, installmentId: installment.id, status: installment.status },
        );
      }

      const netCents = netCentsOf(installment, reversalsByCredit, context);
      assertPayable(installment, {
        contract: contractById.get(installment.salesAgentCommissionId),
        netCents,
        context,
      });

      totalCents += toCents(installment.amount, context);
    }

    const approvedAt = new Date();

    // O WHERE repete `status: 'pending'` de propósito: se o lock não tivesse
    // sido honrado, o contador de linhas afetadas denuncia a corrida.
    const [affected] = await SalesAgentCommissionInstallment.update(
      { status: 'approved', approvedAt },
      { where: { id: ids, status: 'pending' }, transaction },
    );

    if (affected !== ids.length) {
      throw new CommissionPayoutError(
        `aprovação atingiu ${affected} de ${ids.length} lançamentos — lote abortado`,
        { ...context, affected, expected: ids.length },
      );
    }

    logger.info('[commission-payout] lançamentos aprovados', {
      ...context,
      count: ids.length,
      totalAmount: centsToAmount(totalCents),
    });

    return {
      count: ids.length,
      totalAmount: centsToAmount(totalCents),
      installmentIds: ids,
      approvedAt,
    };
  }

  // -------------------------------------------------------------------------
  // 2. Pagar — approved → paid
  // -------------------------------------------------------------------------

  /**
   * Fecha um LOTE de repasse: `approved` → `paid`, com `paidAt` e
   * `payoutBatchId` comuns a todas as linhas do lote.
   *
   * "Pagar" aqui significa exclusivamente REGISTRAR que a comissão foi paga e
   * agrupar os lançamentos em um lote. Nenhuma transferência é disparada —
   * integração bancária/PIX está fora deste ciclo.
   *
   * Ou o lote inteiro é válido, ou nada é escrito: um único lançamento
   * inelegível levanta erro antes do UPDATE e a transaction do caller cai.
   *
   * @param {string[]} installmentIds
   * @param {import('sequelize').Transaction} transaction  obrigatória, do caller
   * @returns {Promise<{batchId, count, totalAmount, installmentIds, paidAt}>}
   */
  async function payApprovedInstallments(installmentIds, transaction) {
    const context = { flow: 'commission-payout' };
    const { ids, installments, contractById, reversalsByCredit } =
      await loadBatch(installmentIds, transaction, context);

    let totalCents = 0;

    for (const installment of installments) {
      if (installment.status !== 'approved') {
        throw new CommissionPayoutError(
          `lançamento ${installment.id} está '${installment.status}': `
          + "só 'approved' pode ser pago",
          { ...context, installmentId: installment.id, status: installment.status },
        );
      }

      const netCents = netCentsOf(installment, reversalsByCredit, context);
      assertPayable(installment, {
        contract: contractById.get(installment.salesAgentCommissionId),
        netCents,
        context,
      });

      // O valor do lote é a soma dos `amount` gravados, e só isso. Nada de
      // percentual atual, plano atual ou commissionMonths.
      totalCents += toCents(installment.amount, context);
    }

    const batchId = generatePayoutBatchId();
    const paidAt = new Date();

    const [affected] = await SalesAgentCommissionInstallment.update(
      { status: 'paid', paidAt, payoutBatchId: batchId },
      { where: { id: ids, status: 'approved' }, transaction },
    );

    if (affected !== ids.length) {
      throw new CommissionPayoutError(
        `pagamento atingiu ${affected} de ${ids.length} lançamentos — lote abortado`,
        { ...context, batchId, affected, expected: ids.length },
      );
    }

    logger.info('[commission-payout] lote de repasse fechado', {
      ...context,
      batchId,
      count: ids.length,
      totalAmount: centsToAmount(totalCents),
    });

    return {
      batchId,
      count: ids.length,
      totalAmount: centsToAmount(totalCents),
      installmentIds: ids,
      paidAt,
    };
  }

  // -------------------------------------------------------------------------
  // 3. Cancelar crédito estornado — pending|approved → cancelled
  // -------------------------------------------------------------------------

  /**
   * Caso B do ciclo: crédito já `approved` que depois recebeu refund.
   *
   * O refund (B3.6) é append-only: lança o reversal e NÃO toca no crédito, que
   * continua `approved`. Voltar o crédito para `pending` em silêncio seria
   * inventar transição, e deixá-lo em `approved` para sempre poluiria a fila
   * de repasse com dinheiro que não existe mais.
   *
   * A transição coerente com o modelo é EXPLÍCITA e fica aqui: um crédito
   * economicamente anulado (líquido <= 0) sai da fila para `cancelled`. O
   * crédito e o reversal continuam intactos como histórico — só o estado da
   * fila de repasse muda.
   *
   * Esta operação nunca é automática: alguém (service, controller, teste)
   * precisa chamá-la com IDs explícitos. E ela NUNCA mexe em `paid` — ver
   * `listPaidReversedInstallments`.
   *
   * @returns {Promise<{count, installmentIds, cancelledAmount}>}
   */
  async function cancelReversedInstallments(installmentIds, transaction) {
    const context = { flow: 'commission-cancel-reversed' };
    const { ids, installments, reversalsByCredit } =
      await loadBatch(installmentIds, transaction, context);

    let cancelledCents = 0;

    for (const installment of installments) {
      if (installment.entryType !== 'credit') {
        throw new CommissionPayoutError(
          `lançamento ${installment.id} é '${installment.entryType}': `
          + 'estorno não é cancelado',
          { ...context, installmentId: installment.id },
        );
      }

      // `paid` fora: dinheiro já repassado não é desfeito por este mecanismo.
      if (installment.status !== 'pending' && installment.status !== 'approved') {
        throw new CommissionPayoutError(
          `lançamento ${installment.id} está '${installment.status}': `
          + "só 'pending' ou 'approved' podem ser cancelados",
          { ...context, installmentId: installment.id, status: installment.status },
        );
      }

      const netCents = netCentsOf(installment, reversalsByCredit, context);
      if (netCents > 0) {
        throw new CommissionPayoutError(
          `lançamento ${installment.id} não foi estornado `
          + `(líquido ${centsToAmount(netCents)}) — cancelamento não se aplica`,
          { ...context, installmentId: installment.id },
        );
      }

      cancelledCents += toCents(installment.amount, context);
    }

    const [affected] = await SalesAgentCommissionInstallment.update(
      { status: 'cancelled' },
      { where: { id: ids, status: ['pending', 'approved'] }, transaction },
    );

    if (affected !== ids.length) {
      throw new CommissionPayoutError(
        `cancelamento atingiu ${affected} de ${ids.length} lançamentos — lote abortado`,
        { ...context, affected, expected: ids.length },
      );
    }

    logger.info('[commission-payout] créditos estornados cancelados', {
      ...context,
      count: ids.length,
    });

    return {
      count: ids.length,
      installmentIds: ids,
      cancelledAmount: centsToAmount(cancelledCents),
    };
  }

  // -------------------------------------------------------------------------
  // 4. Leitura — elegíveis, pendências e totais
  // -------------------------------------------------------------------------

  function scopeWhere({ salesAgentCommissionId = null } = {}) {
    return salesAgentCommissionId
      ? { salesAgentCommissionId }
      : {};
  }

  async function entriesOf(scope, transaction) {
    return SalesAgentCommissionInstallment.findAll({
      where: scopeWhere(scope),
      order: [['installmentNumber', 'ASC']],
      transaction,
    });
  }

  // Indexa os reversals por crédito a partir de uma lista já carregada.
  function indexReversals(entries) {
    const byCredit = new Map();
    for (const entry of entries) {
      if (entry.entryType !== 'reversal' || !entry.reversalOfId) continue;
      const list = byCredit.get(entry.reversalOfId) || [];
      list.push(entry);
      byCredit.set(entry.reversalOfId, list);
    }
    return byCredit;
  }

  /**
   * Créditos que HOJE podem ser aprovados (`pending` e não estornados).
   * Não aprova nada — só lista. A aprovação continua sendo explícita.
   */
  async function listApprovableInstallments(scope = {}, transaction = null) {
    const context = { flow: 'commission-payout-read' };
    const entries = await entriesOf(scope, transaction);
    const reversalsByCredit = indexReversals(entries);

    return entries.filter((entry) => {
      if (entry.entryType !== 'credit' || entry.status !== 'pending') return false;
      return netCentsOf(entry, reversalsByCredit, context) > 0;
    });
  }

  /** Créditos `approved` que ainda valem dinheiro — a fila do próximo lote. */
  async function listPayableInstallments(scope = {}, transaction = null) {
    const context = { flow: 'commission-payout-read' };
    const entries = await entriesOf(scope, transaction);
    const reversalsByCredit = indexReversals(entries);

    return entries.filter((entry) => {
      if (entry.entryType !== 'credit' || entry.status !== 'approved') return false;
      return netCentsOf(entry, reversalsByCredit, context) > 0;
    });
  }

  /**
   * Caso C: crédito JÁ PAGO que depois recebeu refund.
   *
   * O dinheiro saiu. Este ciclo NÃO tenta desfazê-lo — não há débito
   * automático, não há compensação em lote futuro. O reversal fica gravado
   * como histórico e o crédito continua `paid`; o que sobra é uma PENDÊNCIA
   * DE AJUSTE FINANCEIRO, que esta função torna visível em vez de esconder.
   */
  async function listPaidReversedInstallments(scope = {}, transaction = null) {
    const context = { flow: 'commission-payout-read' };
    const entries = await entriesOf(scope, transaction);
    const reversalsByCredit = indexReversals(entries);

    return entries
      .filter((entry) => entry.entryType === 'credit' && entry.status === 'paid')
      .filter((entry) => netCentsOf(entry, reversalsByCredit, context) <= 0)
      .map((entry) => ({
        installment: entry,
        installmentId: entry.id,
        salesAgentCommissionId: entry.salesAgentCommissionId,
        payoutBatchId: entry.payoutBatchId,
        paidAmount: entry.amount,
        reversedAmount: centsToAmount(
          (reversalsByCredit.get(entry.id) || [])
            .reduce((acc, r) => acc + toCents(r.amount, context), 0),
        ),
      }));
  }

  /**
   * Totais para consumo futuro (dashboard/saldo). TUDO derivado dos
   * lançamentos na hora da leitura — nenhum contador mutável é gravado em
   * lugar nenhum, e nada aqui altera dado.
   *
   *   pendingAmount   créditos 'pending', líquidos de estorno
   *   approvedAmount  créditos 'approved', líquidos de estorno
   *   paidAmount      créditos 'paid' pelo valor gravado (o dinheiro saiu;
   *                   estorno posterior NÃO o reduz — vira pendência)
   *   totalAmount     razão algébrico do escopo: Σ créditos − Σ estornos
   *
   * Extras, pelo mesmo critério de derivação:
   *   cancelledAmount, reversedAmount, reversedPaidAmount
   */
  async function summarizeInstallments(scope = {}, transaction = null) {
    const context = { flow: 'commission-payout-read' };
    const entries = await entriesOf(scope, transaction);
    const reversalsByCredit = indexReversals(entries);

    let pending = 0;
    let approved = 0;
    let paid = 0;
    let cancelled = 0;
    let reversed = 0;
    let reversedPaid = 0;
    let total = 0;

    for (const entry of entries) {
      const cents = toCents(entry.amount, context);
      total += cents;

      if (entry.entryType === 'reversal') {
        reversed += cents;
        continue;
      }

      const netCents = netCentsOf(entry, reversalsByCredit, context);

      if (entry.status === 'pending') pending += netCents;
      else if (entry.status === 'approved') approved += netCents;
      else if (entry.status === 'cancelled') cancelled += cents;
      else if (entry.status === 'paid') {
        paid += cents;
        if (netCents <= 0) reversedPaid += cents - netCents;
      }
    }

    return {
      pendingAmount: centsToAmount(pending),
      approvedAmount: centsToAmount(approved),
      paidAmount: centsToAmount(paid),
      cancelledAmount: centsToAmount(cancelled),
      reversedAmount: centsToAmount(reversed),
      // Comissão paga que depois foi estornada: pendência de ajuste, nunca
      // descontada automaticamente.
      reversedPaidAmount: centsToAmount(reversedPaid),
      totalAmount: centsToAmount(total),
      entryCount: entries.length,
    };
  }

  return {
    approveInstallments,
    payApprovedInstallments,
    cancelReversedInstallments,
    listApprovableInstallments,
    listPayableInstallments,
    listPaidReversedInstallments,
    summarizeInstallments,
  };
}

// ---------------------------------------------------------------------------
// Serviço padrão, amarrado ao registry de models da aplicação.
// Require preguiçoso pelo mesmo motivo do engine: permitir carregar o módulo
// em teste sem subir a conexão de app/models/index.js.
// ---------------------------------------------------------------------------

let defaultPayout = null;

function payout() {
  if (!defaultPayout) {
    defaultPayout = buildPayout(require('../models'));
  }
  return defaultPayout;
}

// NOTA SOBRE `app/jobs/commissionJob.js` — CORRIGIDO EM B3.8.
//
// O job era quebrado: (a) aprovava em massa com um UPDATE direto, sem lock,
// sem olhar entryType e sem olhar estorno; (b) pagava com aliases de
// association que não existem mais (`inst.SalesAgentCommission.SalesAgent`;
// o correto é `commission` / `salesAgent`); (c) disparava PIX no Asaas DENTRO
// da transaction e marcava `paid` linha a linha, sem payoutBatchId.
//
// B3.8 reescreveu o job como orquestrador deste service: ele seleciona IDs com
// listApprovableInstallments / listPayableInstallments, agrupa por agente e
// chama approveInstallments / payApprovedInstallments dentro de transactions
// que ele mesmo abre. A liquidação externa ficou FORA da transaction e fora do
// caminho padrão — ver a "LACUNA CONHECIDA" no cabeçalho do job.
//
// Este service NÃO foi alterado por B3.8.

module.exports = {
  approveInstallments: (ids, t) => payout().approveInstallments(ids, t),
  payApprovedInstallments: (ids, t) => payout().payApprovedInstallments(ids, t),
  cancelReversedInstallments: (ids, t) => payout().cancelReversedInstallments(ids, t),
  listApprovableInstallments: (scope, t) => payout().listApprovableInstallments(scope, t),
  listPayableInstallments: (scope, t) => payout().listPayableInstallments(scope, t),
  listPaidReversedInstallments: (scope, t) => payout().listPaidReversedInstallments(scope, t),
  summarizeInstallments: (scope, t) => payout().summarizeInstallments(scope, t),
  buildPayout,
  generatePayoutBatchId,
  CommissionPayoutError,
};
