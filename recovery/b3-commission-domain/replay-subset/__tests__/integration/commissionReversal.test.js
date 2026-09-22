/**
 * B3.6 — estorno de comissão (PAYMENT_REFUNDED / PAYMENT_DELETED).
 *
 * Exercita `reverseCommissionFromRefund` contra o banco local, em cima de
 * créditos gerados pelo próprio engine de B3.5 — o caminho de crédito não é
 * alterado aqui, só consumido.
 *
 * Todos os percentuais e valores são FICTÍCIOS. As fixtures (planos, agentes,
 * tenants, signatures, invoices) são criadas pelo teste e removidas no
 * afterAll — nenhum dado pré-existente é alterado.
 */
const { loadModels } = require('../utils/sequelizeModels');
const { buildEngine } = require('../../app/services/commissionEngine');
const logger = require('../../app/utils/logger');

const db = loadModels();

const {
  sequelize,
  CommissionPlan,
  SalesAgent,
  SalesAgentCommission,
  SalesAgentCommissionTerm,
  SalesAgentCommissionInstallment,
  Invoice,
  Tenant,
  Signature,
} = db;

const engine = buildEngine(db);

jest.setTimeout(60000);

const PLAN_ID = 2; // plano SaaS já existente no banco local (FK de signatures)

const created = {
  signatureIds: [],
  tenantIds: [],
  agentIds: [],
  planIds: [],
  invoiceIds: [],
};

let seq = 0;
function uid(prefix) {
  seq += 1;
  return `${prefix}_B36_${process.pid}_${seq}`;
}

// --------------------------------------------------------------------------
// Fixtures
// --------------------------------------------------------------------------

async function makePlan({ tiers, totalUnits = null, basis = 'billing_month' }) {
  const plan = await CommissionPlan.create(
    {
      name: `TESTE B3.6 ${uid('plan')}`,
      description: 'plano fictício de teste',
      basis,
      tierBasis: 'sequence',
      totalUnits,
      isActive: true,
      tiers: tiers.map((t, i) => ({ tierOrder: i + 1, ...t })),
    },
    { include: [{ association: 'tiers' }] },
  );
  created.planIds.push(plan.id);
  return plan;
}

async function makeScenario({ plan = null, billingCycle = 'monthly', withAgent = true } = {}) {
  let agent = null;

  if (withAgent) {
    agent = await SalesAgent.create({
      commissionMonths: 12,
      defaultCommissionPlanId: plan ? plan.id : null,
    });
    created.agentIds.push(agent.id);
  }

  const tenant = await Tenant.create({
    firstName: `TESTE B3.6 ${uid('tenant')}`,
    salesAgentId: agent ? agent.id : null,
  });
  created.tenantIds.push(tenant.id);

  const signature = await Signature.create({
    asaasId: uid('sub'),
    tenantId: tenant.id,
    planId: PLAN_ID,
    billingCycle,
    start: '2026-01-10',
  });
  created.signatureIds.push(signature.id);

  return { agent, tenant, signature, plan };
}

// Crédito: roda o engine de B3.5 numa transação real e comita.
async function pay(scenario, { value, paymentId, paymentDate = '2026-01-10' }) {
  const t = await sequelize.transaction();
  try {
    await engine.processCommissionFromPayment(
      scenario.signature.asaasId,
      value,
      paymentDate,
      paymentId,
      t,
    );
    await t.commit();
  } catch (error) {
    await t.rollback();
    throw error;
  }
}

// Estorno: mesmo contrato de transação do caller real (o webhook do Asaas).
async function refund(scenario, paymentId) {
  const t = await sequelize.transaction();
  try {
    await engine.reverseCommissionFromRefund(scenario.signature.asaasId, paymentId, t);
    await t.commit();
  } catch (error) {
    await t.rollback();
    throw error;
  }
}

async function contractOf(scenario) {
  return SalesAgentCommission.findOne({
    where: { signatureId: scenario.signature.id, kind: 'direct' },
  });
}

async function entriesOf(scenario) {
  const contract = await contractOf(scenario);
  if (!contract) return [];
  return SalesAgentCommissionInstallment.findAll({
    where: { salesAgentCommissionId: contract.id },
    order: [['installmentNumber', 'ASC']],
  });
}

function creditsOf(entries) {
  return entries.filter((e) => e.entryType === 'credit');
}

function reversalsOf(entries) {
  return entries.filter((e) => e.entryType === 'reversal');
}

// A MESMA derivação que o engine usa: SUM(credit) - SUM(reversal).
async function consumedUnitsOf(scenario) {
  const entries = await entriesOf(scenario);
  return entries.reduce((acc, e) => {
    const units = Number(e.unitsCovered) || 0;
    return e.entryType === 'reversal' ? acc - units : acc + units;
  }, 0);
}

const money = (v) => Number(parseFloat(v).toFixed(2));

beforeAll(async () => {
  await sequelize.authenticate();
});

afterAll(async () => {
  const contracts = await SalesAgentCommission.findAll({
    where: { signatureId: created.signatureIds },
    attributes: ['id'],
  });
  const contractIds = contracts.map((c) => c.id);

  if (contractIds.length) {
    // reversalOfId é auto-FK RESTRICT: os estornos saem antes dos créditos.
    await SalesAgentCommissionInstallment.destroy({
      where: { salesAgentCommissionId: contractIds, entryType: 'reversal' },
    });
    await SalesAgentCommissionInstallment.destroy({
      where: { salesAgentCommissionId: contractIds },
    });
    await SalesAgentCommissionTerm.destroy({ where: { salesAgentCommissionId: contractIds } });
    await SalesAgentCommission.destroy({ where: { id: contractIds } });
  }

  if (created.invoiceIds.length) {
    await Invoice.destroy({ where: { id: created.invoiceIds } });
  }

  await Signature.destroy({ where: { id: created.signatureIds } });
  await Tenant.destroy({ where: { id: created.tenantIds } });
  await SalesAgent.update(
    { defaultCommissionPlanId: null },
    { where: { id: created.agentIds } },
  );
  await SalesAgent.destroy({ where: { id: created.agentIds } });
  await CommissionPlan.destroy({ where: { id: created.planIds } });

  await sequelize.close();
});

// ==========================================================================
describe('B3.6 — estorno de um crédito', () => {
  test('1 + 2 + 3 + 4 + 12. refund com 1 credit gera 1 reversal espelhado e não toca no credit', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 25.0 }],
    });
    const scenario = await makeScenario({ plan });
    const paymentId = uid('pay');

    await pay(scenario, { value: 200, paymentId, paymentDate: '2026-03-05' });

    const [credit] = await entriesOf(scenario);
    const creditSnapshot = credit.toJSON();

    await refund(scenario, paymentId);

    const entries = await entriesOf(scenario);
    expect(entries).toHaveLength(2);

    const reversals = reversalsOf(entries);
    expect(reversals).toHaveLength(1);

    const [reversal] = reversals;

    // 2. aponta para o crédito certo
    expect(reversal.reversalOfId).toBe(credit.id);

    // 3. amount negativo (e baseAmount coerente: amount = base * percent / 100)
    expect(money(reversal.amount)).toBe(-50);
    expect(money(reversal.baseAmount)).toBe(-200);
    expect(money(reversal.percentApplied)).toBe(25);
    expect(money(reversal.baseAmount) * money(reversal.percentApplied) / 100).toBe(
      money(reversal.amount),
    );

    // 4. memória financeira preservada
    expect(reversal.paymentId).toBe(paymentId);
    expect(reversal.salesAgentCommissionId).toBe(credit.salesAgentCommissionId);
    expect(reversal.termId).toBe(credit.termId);
    expect(reversal.billingCycle).toBe(credit.billingCycle);
    expect(reversal.unitFrom).toBe(credit.unitFrom);
    expect(reversal.unitTo).toBe(credit.unitTo);
    expect(reversal.referenceMonth).toBe(credit.referenceMonth);
    expect(new Date(reversal.paymentDate).getTime())
      .toBe(new Date(credit.paymentDate).getTime());

    // unitsCovered POSITIVO: quem subtrai é o entryType, não o sinal
    expect(reversal.unitsCovered).toBe(credit.unitsCovered);
    expect(reversal.unitsCovered).toBeGreaterThan(0);

    // 12. o crédito original continua byte a byte o mesmo
    const creditAfter = await SalesAgentCommissionInstallment.findByPk(credit.id);
    expect(creditAfter).not.toBeNull();
    expect(creditAfter.toJSON()).toEqual(creditSnapshot);
  });

  test('5. consumedUnits volta ao valor anterior ao credit', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 10.0 }],
    });
    const scenario = await makeScenario({ plan, billingCycle: 'annual' });

    const first = uid('pay');
    const second = uid('pay');

    await pay(scenario, { value: 1200, paymentId: first });
    expect(await consumedUnitsOf(scenario)).toBe(12);

    await pay(scenario, { value: 1200, paymentId: second });
    expect(await consumedUnitsOf(scenario)).toBe(24);

    await refund(scenario, second);
    expect(await consumedUnitsOf(scenario)).toBe(12);

    // E o consumo derivado é o que o engine realmente usa: o próximo
    // pagamento reocupa exatamente as unidades liberadas.
    await pay(scenario, { value: 1200, paymentId: uid('pay') });
    const entries = await entriesOf(scenario);
    const last = creditsOf(entries).slice(-1)[0];
    expect([last.unitFrom, last.unitTo]).toEqual([13, 24]);
  });

  test('13. nenhum paidInstallments é alterado pelo estorno', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 10.0 }],
    });
    const scenario = await makeScenario({ plan });
    const paymentId = uid('pay');

    await pay(scenario, { value: 100, paymentId });

    const before = await contractOf(scenario);
    expect(before.paidInstallments).toBe(0);

    // Contador aposentado com valor mentiroso: o estorno não o lê nem o escreve
    await before.update({ paidInstallments: 7 });

    await refund(scenario, paymentId);

    const after = await contractOf(scenario);
    expect(after.paidInstallments).toBe(7);
    expect(after.totalInstallments).toBeNull();
    expect(after.percent).toBeNull();
  });
});

// ==========================================================================
describe('B3.6 — idempotência', () => {
  test('6. refund duplicado não cria segundo reversal', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 10.0 }],
    });
    const scenario = await makeScenario({ plan });
    const paymentId = uid('pay');

    await pay(scenario, { value: 100, paymentId });

    await refund(scenario, paymentId);
    await refund(scenario, paymentId);
    await refund(scenario, paymentId);

    const entries = await entriesOf(scenario);
    expect(creditsOf(entries)).toHaveLength(1);
    expect(reversalsOf(entries)).toHaveLength(1);
    expect(await consumedUnitsOf(scenario)).toBe(0);
  });

  test('a unique do banco barra o segundo reversal mesmo sem o pré-check', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 10.0 }],
    });
    const scenario = await makeScenario({ plan });
    const paymentId = uid('pay');

    await pay(scenario, { value: 100, paymentId });
    await refund(scenario, paymentId);

    const entries = await entriesOf(scenario);
    const [reversal] = reversalsOf(entries);

    // Simula a corrida vencida por outra execução: tenta gravar um segundo
    // reversal para o MESMO contrato+pagamento+faixa, ignorando o pré-check.
    const duplicate = SalesAgentCommissionInstallment.create({
      ...reversal.toJSON(),
      id: undefined,
      installmentNumber: reversal.installmentNumber + 1,
    });

    await expect(duplicate).rejects.toThrow();

    expect(reversalsOf(await entriesOf(scenario))).toHaveLength(1);
  });

  test('9. refund de paymentId sem commission credit é no-op seguro', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 10.0 }],
    });
    const scenario = await makeScenario({ plan });

    // contrato existe (houve um pagamento), mas este paymentId nunca creditou
    await pay(scenario, { value: 100, paymentId: uid('pay') });

    await expect(refund(scenario, uid('pay-nunca-visto'))).resolves.toBeUndefined();

    const entries = await entriesOf(scenario);
    expect(creditsOf(entries)).toHaveLength(1);
    expect(reversalsOf(entries)).toHaveLength(0);
  });

  test('refund de assinatura sem contrato nenhum é no-op seguro', async () => {
    const scenario = await makeScenario({ withAgent: false });

    await expect(refund(scenario, uid('pay'))).resolves.toBeUndefined();
    expect(await contractOf(scenario)).toBeNull();
  });

  test('refund de subscriptionId inexistente ou sem paymentId não faz nada', async () => {
    await expect(
      engine.reverseCommissionFromRefund('sub_inexistente_b36', 'pay_x', null),
    ).resolves.toBeUndefined();
    await expect(
      engine.reverseCommissionFromRefund(null, 'pay_x', null),
    ).resolves.toBeUndefined();
    await expect(
      engine.reverseCommissionFromRefund('sub_x', null, null),
    ).resolves.toBeUndefined();
  });
});

// ==========================================================================
describe('B3.6 — múltiplas faixas e múltiplos contratos', () => {
  test('7. pagamento que atravessa três faixas tem TODOS os credits revertidos', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [
        { fromUnit: 1, toUnit: 1, percent: 40.0 },
        { fromUnit: 2, toUnit: 4, percent: 20.0 },
        { fromUnit: 5, toUnit: null, percent: 10.0 },
      ],
    });
    const scenario = await makeScenario({ plan, billingCycle: 'annual' });
    const paymentId = uid('pay');

    await pay(scenario, { value: 2160, paymentId });

    const credits = creditsOf(await entriesOf(scenario));
    expect(credits).toHaveLength(3);
    expect(credits.map((e) => money(e.amount))).toEqual([72, 108, 144]);

    await refund(scenario, paymentId);

    const entries = await entriesOf(scenario);
    const reversals = reversalsOf(entries);
    expect(reversals).toHaveLength(3);

    // um reversal por crédito, faixa a faixa
    expect(new Set(reversals.map((r) => r.termId)).size).toBe(3);
    expect(reversals.map((r) => r.reversalOfId).sort())
      .toEqual(credits.map((c) => c.id).sort());
    expect(reversals.map((r) => money(r.amount)).sort((a, b) => a - b))
      .toEqual([-144, -108, -72]);

    // o razão do contrato fecha em zero, em dinheiro e em unidades
    const totalAmount = entries.reduce((acc, e) => acc + money(e.amount), 0);
    expect(money(totalAmount)).toBe(0);
    expect(await consumedUnitsOf(scenario)).toBe(0);

    // installmentNumber continua a sequência do contrato, sem reaproveitar
    expect(entries.map((e) => e.installmentNumber)).toEqual([1, 2, 3, 4, 5, 6]);
  });

  test('8. mesmo paymentId em contratos diferentes é revertido separadamente', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 10.0 }],
    });
    const a = await makeScenario({ plan });
    const b = await makeScenario({ plan });
    const paymentId = uid('pay');

    await pay(a, { value: 100, paymentId });
    await pay(b, { value: 200, paymentId });

    // refund chega pela assinatura de A — B não pode ser tocado
    await refund(a, paymentId);

    const entriesA = await entriesOf(a);
    const entriesB = await entriesOf(b);

    expect(reversalsOf(entriesA)).toHaveLength(1);
    expect(money(reversalsOf(entriesA)[0].amount)).toBe(-10);
    expect(await consumedUnitsOf(a)).toBe(0);

    expect(reversalsOf(entriesB)).toHaveLength(0);
    expect(await consumedUnitsOf(b)).toBe(1);

    // e depois o refund de B reverte só B
    await refund(b, paymentId);

    expect(reversalsOf(await entriesOf(a))).toHaveLength(1);
    expect(reversalsOf(await entriesOf(b))).toHaveLength(1);
    expect(money(reversalsOf(await entriesOf(b))[0].amount)).toBe(-20);
  });
});

// ==========================================================================
describe('B3.6 — contrato completed', () => {
  test('contrato esgotado NÃO é reativado em silêncio; o próximo pagamento recalcula', async () => {
    const plan = await makePlan({
      totalUnits: 2,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 10.0 }],
    });
    const scenario = await makeScenario({ plan });

    await pay(scenario, { value: 100, paymentId: uid('pay') });
    const second = uid('pay');
    await pay(scenario, { value: 100, paymentId: second });

    expect((await contractOf(scenario)).status).toBe('completed');

    const warn = jest.spyOn(logger, 'warn');
    await refund(scenario, second);

    // status NÃO muda no estorno — é projeção, recalculada no crédito
    expect((await contractOf(scenario)).status).toBe('completed');
    expect(await consumedUnitsOf(scenario)).toBe(1);

    const logged = warn.mock.calls.map((c) => String(c[0])).join('\n');
    expect(logged).toContain('voltou a ter unidades livres');
    warn.mockRestore();

    // o próximo pagamento encontra remaining > 0 e devolve o contrato a active
    await pay(scenario, { value: 100, paymentId: uid('pay') });
    const contract = await contractOf(scenario);
    expect(contract.status).toBe('completed'); // reocupou a 2ª unidade
    expect(await consumedUnitsOf(scenario)).toBe(2);

    const credits = creditsOf(await entriesOf(scenario));
    expect(credits.map((e) => e.unitFrom)).toEqual([1, 2, 2]);
  });
});

// ==========================================================================
describe('B3.6 — transação e erros', () => {
  test('10. o estorno usa a transaction recebida — rollback não deixa rastro', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [
        { fromUnit: 1, toUnit: 1, percent: 40.0 },
        { fromUnit: 2, toUnit: null, percent: 20.0 },
      ],
    });
    const scenario = await makeScenario({ plan, billingCycle: 'annual' });
    const paymentId = uid('pay');

    await pay(scenario, { value: 1200, paymentId });
    const contract = await contractOf(scenario);

    const t = await sequelize.transaction();
    await engine.reverseCommissionFromRefund(scenario.signature.asaasId, paymentId, t);

    // Dentro da transação os reversals existem...
    const inside = await SalesAgentCommissionInstallment.findAll({
      where: { salesAgentCommissionId: contract.id, entryType: 'reversal' },
      transaction: t,
    });
    expect(inside).toHaveLength(2);

    // ...e fora dela, ainda não (nenhum commit próprio foi dado)
    expect(
      await SalesAgentCommissionInstallment.count({
        where: { salesAgentCommissionId: contract.id, entryType: 'reversal' },
      }),
    ).toBe(0);

    await t.rollback();

    const entries = await entriesOf(scenario);
    expect(reversalsOf(entries)).toHaveLength(0);
    expect(creditsOf(entries)).toHaveLength(2);
    expect(await consumedUnitsOf(scenario)).toBe(12);
  });

  test('11. falha de insert não é engolida', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 10.0 }],
    });
    const scenario = await makeScenario({ plan });
    const paymentId = uid('pay');

    await pay(scenario, { value: 100, paymentId });

    const spy = jest
      .spyOn(SalesAgentCommissionInstallment, 'create')
      .mockRejectedValueOnce(new Error('INSERT do estorno explodiu'));
    const error = jest.spyOn(logger, 'error');

    await expect(refund(scenario, paymentId)).rejects.toThrow('INSERT do estorno explodiu');

    const logged = error.mock.calls.map((c) => String(c[0])).join('\n');
    expect(logged).toContain('falha ao estornar comissão');

    spy.mockRestore();
    error.mockRestore();

    // transação revertida: o crédito segue lá, sem estorno pela metade
    const entries = await entriesOf(scenario);
    expect(creditsOf(entries)).toHaveLength(1);
    expect(reversalsOf(entries)).toHaveLength(0);
  });
});

// ==========================================================================
describe('B3.6 — integração com o refund da invoice', () => {
  /**
   * 14. O `_handlePaymentRefunded` do asaas.controller não pode ser exigido
   * aqui: `app/models/index.js` puxa `session.js`, que é model do Mongoose, e
   * o resolver do Jest 26 quebra no `node:async_hooks`. Isso é limitação
   * pré-existente da infra de teste (a mesma que motivou
   * `__tests__/utils/sequelizeModels.js`), não do estorno.
   *
   * O teste reproduz então os DOIS efeitos do handler, na ordem e na MESMA
   * transação: refund da invoice primeiro, estorno da comissão depois.
   */
  test('14. invoice vira REFUNDED e a comissão é estornada na mesma transação', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 10.0 }],
    });
    const scenario = await makeScenario({ plan });
    const paymentId = uid('pay');

    await pay(scenario, { value: 100, paymentId });

    const invoice = await Invoice.create({
      tenantId: scenario.tenant.id,
      customerName: 'TESTE B3.6',
      paymentId,
      amount: 100,
      description: 'Assinatura SaaS (fixture de teste)',
      status: 'PENDING',
    });
    created.invoiceIds.push(invoice.id);

    const t = await sequelize.transaction();
    try {
      await Invoice.update(
        { status: 'REFUNDED', refundedAt: new Date() },
        { where: { paymentId }, transaction: t },
      );
      await engine.reverseCommissionFromRefund(scenario.signature.asaasId, paymentId, t);
      await t.commit();
    } catch (err) {
      await t.rollback();
      throw err;
    }

    const refunded = await Invoice.findByPk(invoice.id);
    expect(refunded.status).toBe('REFUNDED');
    expect(refunded.refundedAt).not.toBeNull();

    const entries = await entriesOf(scenario);
    expect(reversalsOf(entries)).toHaveLength(1);
    expect(await consumedUnitsOf(scenario)).toBe(0);
  });

  test('invoice do refund continua REFUNDED mesmo quando não há comissão a estornar', async () => {
    const scenario = await makeScenario({ withAgent: false });
    const paymentId = uid('pay');

    const invoice = await Invoice.create({
      tenantId: scenario.tenant.id,
      customerName: 'TESTE B3.6',
      paymentId,
      amount: 100,
      description: 'Assinatura SaaS (fixture de teste)',
      status: 'PENDING',
    });
    created.invoiceIds.push(invoice.id);

    const t = await sequelize.transaction();
    await Invoice.update(
      { status: 'REFUNDED', refundedAt: new Date() },
      { where: { paymentId }, transaction: t },
    );
    await engine.reverseCommissionFromRefund(scenario.signature.asaasId, paymentId, t);
    await t.commit();

    expect((await Invoice.findByPk(invoice.id)).status).toBe('REFUNDED');
    expect(await contractOf(scenario)).toBeNull();
  });
});
