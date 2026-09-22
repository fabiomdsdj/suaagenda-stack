/**
 * B3.5 — commissionEngine sobre planos/faixas.
 *
 * Exercita o engine de verdade contra o banco local: contrato fechado a partir
 * do plano padrão do agente, snapshot de faixas, rateio por unidade e
 * idempotência por contrato + pagamento.
 *
 * Todos os percentuais e valores aqui são FICTÍCIOS. As fixtures (planos,
 * agentes, tenants, signatures) são criadas pelo teste e removidas no afterAll
 * — nenhum dado pré-existente é alterado.
 */
const { loadModels } = require('../utils/sequelizeModels');
const {
  buildEngine,
  buildSegments,
  allocateBases,
} = require('../../app/services/commissionEngine');
const logger = require('../../app/utils/logger');

const db = loadModels();

const {
  sequelize,
  CommissionPlan,
  SalesAgent,
  SalesAgentCommission,
  SalesAgentCommissionTerm,
  SalesAgentCommissionInstallment,
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
};

let seq = 0;
function uid(prefix) {
  seq += 1;
  return `${prefix}_B35_${process.pid}_${seq}`;
}

// --------------------------------------------------------------------------
// Fixtures
// --------------------------------------------------------------------------

async function makePlan({ tiers, totalUnits = null, basis = 'billing_month' }) {
  const plan = await CommissionPlan.create(
    {
      name: `TESTE B3.5 ${uid('plan')}`,
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

/**
 * Monta um cenário isolado: agente (opcionalmente com plano padrão), tenant
 * apontando para ele e signature própria.
 */
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
    firstName: `TESTE B3.5 ${uid('tenant')}`,
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

// Roda o engine dentro de uma transação real e comita.
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

async function contractOf(scenario) {
  return SalesAgentCommission.findOne({
    where: { signatureId: scenario.signature.id, kind: 'direct' },
    include: [{ association: 'terms' }],
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
    await SalesAgentCommissionInstallment.destroy({
      where: { salesAgentCommissionId: contractIds },
    });
    await SalesAgentCommissionTerm.destroy({ where: { salesAgentCommissionId: contractIds } });
    await SalesAgentCommission.destroy({ where: { id: contractIds } });
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
describe('B3.5 — resolução do agente e do plano', () => {
  test('1. tenant sem SalesAgent não gera comissão', async () => {
    const scenario = await makeScenario({ withAgent: false });

    await pay(scenario, { value: 100, paymentId: uid('pay') });

    expect(await contractOf(scenario)).toBeNull();
  });

  test('2. agente sem defaultCommissionPlanId não gera comissão e registra log', async () => {
    const scenario = await makeScenario({ plan: null });
    const warn = jest.spyOn(logger, 'warn');

    await pay(scenario, { value: 100, paymentId: uid('pay') });

    expect(await contractOf(scenario)).toBeNull();
    expect(await entriesOf(scenario)).toHaveLength(0);

    const logged = warn.mock.calls.map((c) => String(c[0])).join('\n');
    expect(logged).toContain('defaultCommissionPlanId');

    warn.mockRestore();
  });
});

// ==========================================================================
describe('B3.5 — contrato e snapshot', () => {
  test('3. primeiro pagamento fecha o contrato e copia as faixas', async () => {
    const plan = await makePlan({
      totalUnits: 12,
      tiers: [
        { fromUnit: 1, toUnit: 3, percent: 40.0 },
        { fromUnit: 4, toUnit: 12, percent: 20.0 },
        { fromUnit: 13, toUnit: null, percent: 10.0 },
      ],
    });
    const scenario = await makeScenario({ plan });

    await pay(scenario, { value: 100, paymentId: uid('pay') });

    const contract = await contractOf(scenario);
    expect(contract).not.toBeNull();
    expect(contract.kind).toBe('direct');
    expect(contract.status).toBe('active');
    expect(contract.commissionPlanId).toBe(plan.id);
    expect(contract.basis).toBe('billing_month');
    expect(contract.tierBasis).toBe('sequence');
    expect(contract.totalUnits).toBe(12);
    expect(contract.startDate).toBe('2026-01-10');

    // Campos aposentados continuam intocados
    expect(contract.percent).toBeNull();
    expect(contract.endDate).toBeNull();
    expect(contract.commissionMonths).toBeNull();
    expect(contract.totalInstallments).toBeNull();
    expect(contract.paidInstallments).toBe(0);

    const terms = contract.terms.sort((a, b) => a.tierOrder - b.tierOrder);
    expect(terms).toHaveLength(3);
    expect(terms.map((t) => [t.fromUnit, t.toUnit, money(t.percent)])).toEqual([
      [1, 3, 40], [4, 12, 20], [13, null, 10],
    ]);
  });

  test('4. segundo pagamento reutiliza o contrato e não recria terms', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 10.0 }],
    });
    const scenario = await makeScenario({ plan });

    await pay(scenario, { value: 100, paymentId: uid('pay') });
    const first = await contractOf(scenario);

    await pay(scenario, { value: 100, paymentId: uid('pay') });
    const second = await contractOf(scenario);

    expect(second.id).toBe(first.id);
    expect(second.terms).toHaveLength(1);

    const contracts = await SalesAgentCommission.count({
      where: { signatureId: scenario.signature.id },
    });
    expect(contracts).toBe(1);
    expect(await entriesOf(scenario)).toHaveLength(2);
  });

  test('mudar o plano depois não muda o contrato já fechado', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 30.0 }],
    });
    const scenario = await makeScenario({ plan });

    await pay(scenario, { value: 100, paymentId: uid('pay') });

    await db.CommissionPlanTier.update(
      { percent: 1.0 },
      { where: { commissionPlanId: plan.id } },
    );
    await plan.update({ totalUnits: 1, isActive: false });

    await pay(scenario, { value: 100, paymentId: uid('pay') });

    const entries = await entriesOf(scenario);
    expect(entries.map((e) => money(e.percentApplied))).toEqual([30, 30]);
    expect((await contractOf(scenario)).totalUnits).toBeNull();
  });
});

// ==========================================================================
describe('B3.5 — faixas e percentuais', () => {
  test('5. faixa única aplica o mesmo percentual em todo pagamento', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 25.0 }],
    });
    const scenario = await makeScenario({ plan });

    await pay(scenario, { value: 200, paymentId: uid('pay') });
    await pay(scenario, { value: 200, paymentId: uid('pay') });

    const entries = await entriesOf(scenario);
    expect(entries).toHaveLength(2);
    expect(entries.map((e) => money(e.amount))).toEqual([50, 50]);
    expect(entries.map((e) => [e.unitFrom, e.unitTo])).toEqual([[1, 1], [2, 2]]);
  });

  test('6. primeiro mês com percentual diferente dos demais', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [
        { fromUnit: 1, toUnit: 1, percent: 50.0 },
        { fromUnit: 2, toUnit: null, percent: 10.0 },
      ],
    });
    const scenario = await makeScenario({ plan });

    await pay(scenario, { value: 100, paymentId: uid('pay') });
    await pay(scenario, { value: 100, paymentId: uid('pay') });
    await pay(scenario, { value: 100, paymentId: uid('pay') });

    const entries = await entriesOf(scenario);
    expect(entries.map((e) => money(e.amount))).toEqual([50, 10, 10]);
    expect(entries.map((e) => money(e.percentApplied))).toEqual([50, 10, 10]);
  });

  test('7 + 13 + 14. pagamento anual atravessa três faixas e rateia o valor', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [
        { fromUnit: 1, toUnit: 1, percent: 40.0 },
        { fromUnit: 2, toUnit: 4, percent: 20.0 },
        { fromUnit: 5, toUnit: null, percent: 10.0 },
      ],
    });
    const scenario = await makeScenario({ plan, billingCycle: 'annual' });

    await pay(scenario, { value: 2160, paymentId: uid('pay') });

    const entries = await entriesOf(scenario);
    expect(entries).toHaveLength(3);

    expect(entries.map((e) => [e.unitFrom, e.unitTo, e.unitsCovered])).toEqual([
      [1, 1, 1], [2, 4, 3], [5, 12, 8],
    ]);
    // base = 2160 * unidades / 12
    expect(entries.map((e) => money(e.baseAmount))).toEqual([180, 540, 1440]);
    expect(entries.map((e) => money(e.amount))).toEqual([72, 108, 144]);

    // A soma das bases é exatamente o valor rateado
    const totalBase = entries.reduce((acc, e) => acc + money(e.baseAmount), 0);
    expect(money(totalBase)).toBe(2160);

    // installmentNumber é ordinal coerente, e não seletor de faixa
    expect(entries.map((e) => e.installmentNumber)).toEqual([1, 2, 3]);
    expect(entries.every((e) => e.entryType === 'credit')).toBe(true);
    expect(entries.every((e) => e.status === 'pending')).toBe(true);
    expect(entries.every((e) => e.billingCycle === 'annual')).toBe(true);
    expect(new Set(entries.map((e) => e.termId)).size).toBe(3);
  });

  test('15. resíduo de centavos cai determinísticamente no último segmento', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [
        { fromUnit: 1, toUnit: 1, percent: 40.0 },
        { fromUnit: 2, toUnit: null, percent: 20.0 },
      ],
    });
    const scenario = await makeScenario({ plan, billingCycle: 'annual' });

    // 100 / 12 não fecha em centavos: 8,3333...
    await pay(scenario, { value: 100, paymentId: uid('pay') });

    const entries = await entriesOf(scenario);
    expect(entries.map((e) => money(e.baseAmount))).toEqual([8.33, 91.67]);
    expect(money(entries.reduce((a, e) => a + money(e.baseAmount), 0))).toBe(100);
    expect(entries.map((e) => money(e.amount))).toEqual([3.33, 18.33]);
  });

  test('cálculo puro: buildSegments recorta as faixas pelo intervalo do pagamento', () => {
    const terms = [
      { id: 'a', tierOrder: 1, fromUnit: 1, toUnit: 3, percent: 40 },
      { id: 'b', tierOrder: 2, fromUnit: 4, toUnit: 12, percent: 20 },
      { id: 'c', tierOrder: 3, fromUnit: 13, toUnit: null, percent: 10 },
    ];

    expect(buildSegments(terms, 1, 1).map((s) => [s.term.id, s.unitsCovered])).toEqual([['a', 1]]);
    expect(buildSegments(terms, 3, 5).map((s) => [s.term.id, s.unitFrom, s.unitTo])).toEqual([
      ['a', 3, 3], ['b', 4, 5],
    ]);
    // faixa aberta absorve tudo que passa do fim
    expect(buildSegments(terms, 12, 24).map((s) => [s.term.id, s.unitFrom, s.unitTo])).toEqual([
      ['b', 12, 12], ['c', 13, 24],
    ]);
  });

  test('cálculo puro: allocateBases fecha a soma das bases', () => {
    const segments = [
      { unitsCovered: 1 }, { unitsCovered: 1 }, { unitsCovered: 1 },
    ];
    const allocated = allocateBases(segments, 10000, 3); // R$ 100,00 / 3
    expect(allocated.map((s) => s.baseCents)).toEqual([3333, 3333, 3334]);
    expect(allocated.reduce((a, s) => a + s.baseCents, 0)).toBe(10000);
  });
});

// ==========================================================================
describe('B3.5 — unidade de consumo por billingCycle', () => {
  const cases = [
    ['10. monthly', 'monthly', 1, [[1, 1]]],
    ['11. quarterly', 'quarterly', 3, [[1, 3]]],
    ['12. annual', 'annual', 12, [[1, 12]]],
  ];

  test.each(cases)('%s consome as unidades certas', async (_name, cycle, units, ranges) => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 10.0 }],
    });
    const scenario = await makeScenario({ plan, billingCycle: cycle });

    await pay(scenario, { value: 120, paymentId: uid('pay') });

    const entries = await entriesOf(scenario);
    expect(entries.map((e) => [e.unitFrom, e.unitTo])).toEqual(ranges);
    expect(entries[0].unitsCovered).toBe(units);
    expect(money(entries[0].baseAmount)).toBe(120);
    expect(money(entries[0].amount)).toBe(12);
  });

  test('basis = payment conta 1 unidade por pagamento, ignorando o ciclo', async () => {
    const plan = await makePlan({
      basis: 'payment',
      totalUnits: null,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 10.0 }],
    });
    const scenario = await makeScenario({ plan, billingCycle: 'annual' });

    await pay(scenario, { value: 1200, paymentId: uid('pay') });

    const entries = await entriesOf(scenario);
    expect(entries).toHaveLength(1);
    expect([entries[0].unitFrom, entries[0].unitTo]).toEqual([1, 1]);
    expect(money(entries[0].baseAmount)).toBe(1200);
  });

  test('billingCycle indeterminado aborta com erro explícito (nunca assume 1)', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 10.0 }],
    });
    const scenario = await makeScenario({ plan, billingCycle: null });

    await expect(pay(scenario, { value: 100, paymentId: uid('pay') })).rejects.toThrow(
      /billingCycle indeterminado/,
    );

    expect(await entriesOf(scenario)).toHaveLength(0);
  });
});

// ==========================================================================
describe('B3.5 — limite do contrato', () => {
  test('8 + 9 + 19. contrato de 12 unidades completa no 12º e ignora o 13º', async () => {
    const plan = await makePlan({
      totalUnits: 12,
      tiers: [
        { fromUnit: 1, toUnit: 3, percent: 40.0 },
        { fromUnit: 4, toUnit: null, percent: 20.0 },
      ],
    });
    const scenario = await makeScenario({ plan });

    for (let month = 1; month <= 11; month += 1) {
      await pay(scenario, { value: 100, paymentId: uid('pay') });
      const contract = await contractOf(scenario);
      expect(contract.status).toBe('active');
    }

    await pay(scenario, { value: 100, paymentId: uid('pay') });
    expect((await contractOf(scenario)).status).toBe('completed');
    expect(await entriesOf(scenario)).toHaveLength(12);

    // 13º mês: nada é gerado
    await pay(scenario, { value: 100, paymentId: uid('pay') });
    expect(await entriesOf(scenario)).toHaveLength(12);
    expect((await contractOf(scenario)).status).toBe('completed');

    const entries = await entriesOf(scenario);
    expect(entries.map((e) => money(e.amount))).toEqual([
      40, 40, 40, 20, 20, 20, 20, 20, 20, 20, 20, 20,
    ]);
  });

  test('pagamento anual além do limite comissiona só as unidades restantes', async () => {
    const plan = await makePlan({
      totalUnits: 6,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 10.0 }],
    });
    const scenario = await makeScenario({ plan, billingCycle: 'annual' });

    await pay(scenario, { value: 1200, paymentId: uid('pay') });

    const entries = await entriesOf(scenario);
    expect(entries).toHaveLength(1);
    expect([entries[0].unitFrom, entries[0].unitTo, entries[0].unitsCovered]).toEqual([1, 6, 6]);
    // rateio sobre 6 das 12 unidades do pagamento
    expect(money(entries[0].baseAmount)).toBe(600);
    expect(money(entries[0].amount)).toBe(60);
    expect((await contractOf(scenario)).status).toBe('completed');
  });

  test('20. contrato sem totalUnits permanece active indefinidamente', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 10.0 }],
    });
    const scenario = await makeScenario({ plan, billingCycle: 'annual' });

    await pay(scenario, { value: 1200, paymentId: uid('pay') });
    await pay(scenario, { value: 1200, paymentId: uid('pay') });

    const contract = await contractOf(scenario);
    expect(contract.status).toBe('active');
    expect(contract.totalUnits).toBeNull();

    const entries = await entriesOf(scenario);
    expect(entries.map((e) => [e.unitFrom, e.unitTo])).toEqual([[1, 12], [13, 24]]);
  });
});

// ==========================================================================
describe('B3.5 — idempotência e consumo derivado', () => {
  test('16. mesmo paymentId no mesmo contrato não duplica comissão', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 10.0 }],
    });
    const scenario = await makeScenario({ plan });
    const paymentId = uid('pay');

    await pay(scenario, { value: 100, paymentId });
    await pay(scenario, { value: 100, paymentId });
    await pay(scenario, { value: 100, paymentId });

    const entries = await entriesOf(scenario);
    expect(entries).toHaveLength(1);
    expect((await contractOf(scenario)).status).toBe('active');
  });

  test('17. dois contratos diferentes podem usar o mesmo paymentId', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 10.0 }],
    });
    const a = await makeScenario({ plan });
    const b = await makeScenario({ plan });
    const paymentId = uid('pay');

    await pay(a, { value: 100, paymentId });
    await pay(b, { value: 200, paymentId });

    const entriesA = await entriesOf(a);
    const entriesB = await entriesOf(b);
    expect(entriesA).toHaveLength(1);
    expect(entriesB).toHaveLength(1);
    expect(money(entriesA[0].amount)).toBe(10);
    expect(money(entriesB[0].amount)).toBe(20);

    const shared = await SalesAgentCommissionInstallment.findAll({ where: { paymentId } });
    expect(shared).toHaveLength(2);
    expect(new Set(shared.map((e) => e.salesAgentCommissionId)).size).toBe(2);
  });

  test('18. consumedUnits é derivado dos installments, não de paidInstallments', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 10.0 }],
    });
    const scenario = await makeScenario({ plan });

    await pay(scenario, { value: 100, paymentId: uid('pay') });
    await pay(scenario, { value: 100, paymentId: uid('pay') });

    const contract = await contractOf(scenario);
    expect(contract.paidInstallments).toBe(0);

    // Contador mutável mentiroso não influencia o cálculo
    await contract.update({ paidInstallments: 99 });

    await pay(scenario, { value: 100, paymentId: uid('pay') });
    let entries = await entriesOf(scenario);
    expect(entries.map((e) => e.unitFrom)).toEqual([1, 2, 3]);

    // Apagando um lançamento, o consumo recua — porque é derivado
    await entries[2].destroy();
    await entries[1].destroy();

    await pay(scenario, { value: 100, paymentId: uid('pay') });
    entries = await entriesOf(scenario);
    expect(entries.map((e) => e.unitFrom).sort((x, y) => x - y)).toEqual([1, 2]);
  });
});

// ==========================================================================
describe('B3.5 — erros e transação', () => {
  test('21. falha no INSERT sobe para o caller, sem catch silencioso', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 10.0 }],
    });
    const scenario = await makeScenario({ plan });

    const spy = jest
      .spyOn(SalesAgentCommissionInstallment, 'create')
      .mockRejectedValueOnce(new Error('INSERT explodiu'));
    const error = jest.spyOn(logger, 'error');

    await expect(pay(scenario, { value: 100, paymentId: uid('pay') })).rejects.toThrow(
      'INSERT explodiu',
    );

    expect(error).toHaveBeenCalled();
    const logged = error.mock.calls.map((c) => String(c[0])).join('\n');
    expect(logged).toContain('falha ao processar comissão');

    spy.mockRestore();
    error.mockRestore();

    // Transação foi revertida: nada persistiu
    expect(await contractOf(scenario)).toBeNull();
  });

  test('22. todo insert usa a transaction recebida — rollback não deixa rastro', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [
        { fromUnit: 1, toUnit: 1, percent: 40.0 },
        { fromUnit: 2, toUnit: null, percent: 20.0 },
      ],
    });
    const scenario = await makeScenario({ plan, billingCycle: 'annual' });
    const paymentId = uid('pay');

    const t = await sequelize.transaction();
    await engine.processCommissionFromPayment(
      scenario.signature.asaasId,
      1200,
      '2026-01-10',
      paymentId,
      t,
    );

    // Dentro da transação tudo existe...
    const inside = await SalesAgentCommissionInstallment.findAll({
      where: { paymentId },
      transaction: t,
    });
    expect(inside).toHaveLength(2);

    await t.rollback();

    // ...e nada sobra depois do rollback: contrato, terms e lançamentos
    expect(await contractOf(scenario)).toBeNull();
    expect(
      await SalesAgentCommissionInstallment.count({ where: { paymentId } }),
    ).toBe(0);
    expect(
      await SalesAgentCommission.count({ where: { signatureId: scenario.signature.id } }),
    ).toBe(0);
  });

  test('subscriptionId ou paymentId ausente não faz nada', async () => {
    await expect(
      engine.processCommissionFromPayment(null, 100, '2026-01-10', 'pay_x', null),
    ).resolves.toBeUndefined();
    await expect(
      engine.processCommissionFromPayment('sub_x', 100, '2026-01-10', null, null),
    ).resolves.toBeUndefined();
  });

  test('signature inexistente não gera comissão', async () => {
    await expect(
      engine.processCommissionFromPayment('sub_inexistente_b35', 100, '2026-01-10', 'pay_y', null),
    ).resolves.toBeUndefined();
  });
});

// ==========================================================================
describe('B3.5 — memória de cálculo do lançamento', () => {
  test('o lançamento guarda contexto do pagamento e a memória do cálculo', async () => {
    const plan = await makePlan({
      totalUnits: null,
      tiers: [{ fromUnit: 1, toUnit: null, percent: 15.0 }],
    });
    const scenario = await makeScenario({ plan, billingCycle: 'quarterly' });
    const paymentId = uid('pay');

    await pay(scenario, { value: 300, paymentId, paymentDate: '2026-03-05' });

    const [entry] = await entriesOf(scenario);
    const contract = await contractOf(scenario);

    expect(entry.paymentId).toBe(paymentId);
    expect(entry.referenceMonth).toBe('2026-03');
    expect(entry.billingCycle).toBe('quarterly');
    expect(entry.termId).toBe(contract.terms[0].id);
    expect(entry.unitsCovered).toBe(3);
    expect(money(entry.baseAmount)).toBe(300);
    expect(money(entry.percentApplied)).toBe(15);
    expect(money(entry.amount)).toBe(45);
    expect(entry.entryType).toBe('credit');

    // paymentDate é a data do pagamento do tenant (antes isso ia no dueDate)
    const paymentDate = new Date(entry.paymentDate);
    expect(paymentDate.getFullYear()).toBe(2026);
    expect(paymentDate.getMonth()).toBe(2);
    expect(paymentDate.getDate()).toBe(5);
  });
});
