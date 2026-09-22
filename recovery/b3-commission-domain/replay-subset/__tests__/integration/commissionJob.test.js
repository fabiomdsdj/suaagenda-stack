/**
 * B3.8 — `commissionJob` como orquestrador do payout.
 *
 * O job é exercitado contra o banco local, em cima de créditos e estornos
 * gerados pelo engine de B3.5/B3.6 e movimentados pelo service de B3.7.
 * Nenhum desses três é alterado aqui — só consumidos.
 *
 * O que estes testes provam, em uma frase: o job não tem regra financeira
 * própria. Toda mudança de estado passa pelo `commissionPayout`, e quando o
 * service é substituído por um dublê que não escreve nada, o banco não muda.
 *
 * Todos os percentuais e valores são FICTÍCIOS. As fixtures (planos, agentes,
 * tenants, signatures) são criadas pelo teste e removidas no afterAll.
 */
const { loadModels } = require('../utils/sequelizeModels');
const { buildEngine } = require('../../app/services/commissionEngine');
const { buildPayout } = require('../../app/services/commissionPayout');
const {
  buildCommissionJob,
  buildAsaasPixTransfer,
  CommissionJobError,
} = require('../../app/jobs/commissionJob');

const db = loadModels();

const {
  sequelize,
  CommissionPlan,
  CommissionPlanTier,
  SalesAgent,
  SalesAgentCommission,
  SalesAgentCommissionTerm,
  SalesAgentCommissionInstallment,
  Tenant,
  Signature,
} = db;

const engine = buildEngine(db);
const payout = buildPayout(db);

jest.setTimeout(120000);

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
  return `${prefix}_B38_${process.pid}_${seq}`;
}

// Logger mudo, mas inspecionável: vários testes checam que o job GRITOU.
function makeLog() {
  return { info: jest.fn(), warn: jest.fn(), error: jest.fn() };
}

// --------------------------------------------------------------------------
// Fixtures
// --------------------------------------------------------------------------

async function makePlan({ tiers, totalUnits = null, basis = 'billing_month' }) {
  const plan = await CommissionPlan.create(
    {
      name: `TESTE B3.8 ${uid('plan')}`,
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

async function makeScenario({ plan = null, billingCycle = 'monthly', pixKey = null } = {}) {
  const agent = await SalesAgent.create({
    commissionMonths: 12,
    commissionPercent: 10,
    pixKey,
    defaultCommissionPlanId: plan ? plan.id : null,
  });
  created.agentIds.push(agent.id);

  const tenant = await Tenant.create({
    firstName: `TESTE B3.8 ${uid('tenant')}`,
    salesAgentId: agent.id,
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
      scenario.signature.asaasId, value, paymentDate, paymentId, t,
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

// Escopo das listagens: sempre restrito aos contratos do cenário, para não
// varrer lançamentos de outros testes no mesmo banco.
async function scopeOf(...scenarios) {
  const contracts = await Promise.all(scenarios.map(contractOf));
  return { salesAgentCommissionId: contracts.map((c) => c.id) };
}

const money = (v) => Number(parseFloat(v).toFixed(2));

// Plano simples de uma faixa, reaproveitado pela maioria dos testes.
function simpleTiers() {
  return [{ fromUnit: 1, toUnit: null, percent: 10 }];
}

// Job real: models reais, payout real. `log` injetado para inspeção.
function makeJob({ payoutImpl = payout, log = makeLog() } = {}) {
  return { job: buildCommissionJob({ models: db, payout: payoutImpl, log }), log };
}

// Dublê do payout: listagens reais (para o job selecionar de verdade), mas as
// operações de escrita substituídas. Serve para provar que o job não escreve.
function spyPayout(overrides = {}) {
  const calls = { approve: [], pay: [], listApprovable: 0, listPayable: 0 };

  const wrapped = {
    listApprovableInstallments: async (scope, t) => {
      calls.listApprovable += 1;
      return payout.listApprovableInstallments(scope, t);
    },
    listPayableInstallments: async (scope, t) => {
      calls.listPayable += 1;
      return payout.listPayableInstallments(scope, t);
    },
    approveInstallments: async (ids, t) => {
      calls.approve.push({ ids, transaction: t });
      if (overrides.approveInstallments) return overrides.approveInstallments(ids, t);
      return payout.approveInstallments(ids, t);
    },
    payApprovedInstallments: async (ids, t) => {
      calls.pay.push({ ids, transaction: t });
      if (overrides.payApprovedInstallments) return overrides.payApprovedInstallments(ids, t);
      return payout.payApprovedInstallments(ids, t);
    },
  };

  return { payout: wrapped, calls };
}

// --------------------------------------------------------------------------

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
describe('B3.8 — seleção e aprovação', () => {
  test('1. o job encontra os lançamentos elegíveis do escopo', async () => {
    const plan = await makePlan({ tiers: simpleTiers() });
    const scenario = await makeScenario({ plan });
    await pay(scenario, { value: 100, paymentId: uid('pay') });
    await pay(scenario, { value: 200, paymentId: uid('pay'), paymentDate: '2026-02-10' });

    const { job } = makeJob();
    const result = await job.run({ scope: await scopeOf(scenario), settlement: 'none' });

    expect(result.approval.candidates).toBe(2);
    expect(result.approval.eligible).toBe(2);
    expect(result.approval.approved).toHaveLength(1); // um lote, um agente
    expect(result.approval.approved[0].count).toBe(2);
    expect(result.approval.approved[0].salesAgentId).toBe(scenario.agent.id);
    expect(result.ok).toBe(true);
  });

  test('2. a seleção vem de listApprovableInstallments / listPayableInstallments', async () => {
    const plan = await makePlan({ tiers: simpleTiers() });
    const scenario = await makeScenario({ plan });
    await pay(scenario, { value: 100, paymentId: uid('pay') });

    const { payout: spied, calls } = spyPayout();
    const { job } = makeJob({ payoutImpl: spied });
    await job.run({ scope: await scopeOf(scenario), settlement: 'none' });

    expect(calls.listApprovable).toBe(1);
    expect(calls.listPayable).toBe(1);
  });

  test('3. a aprovação passa por approveInstallments, com a transaction do job', async () => {
    const plan = await makePlan({ tiers: simpleTiers() });
    const scenario = await makeScenario({ plan });
    await pay(scenario, { value: 100, paymentId: uid('pay') });

    const { payout: spied, calls } = spyPayout();
    const { job } = makeJob({ payoutImpl: spied });
    await job.run({ scope: await scopeOf(scenario), settlement: 'none' });

    expect(calls.approve).toHaveLength(1);
    expect(calls.approve[0].ids).toHaveLength(1);
    // transaction é obrigatória no service — o job precisa tê-la aberto.
    expect(calls.approve[0].transaction).toBeTruthy();
    expect(typeof calls.approve[0].transaction.commit).toBe('function');

    const [credit] = creditsOf(await entriesOf(scenario));
    expect(credit.status).toBe('approved');
    expect(credit.approvedAt).toBeTruthy();
  });

  test('a carência de aprovação segura crédito recente e não o aprova', async () => {
    const plan = await makePlan({ tiers: simpleTiers() });
    const scenario = await makeScenario({ plan });
    const today = new Date();
    const iso = today.toISOString().slice(0, 10);
    await pay(scenario, { value: 100, paymentId: uid('pay'), paymentDate: iso });

    const { job } = makeJob();
    const result = await job.run({
      scope: await scopeOf(scenario),
      approvalHoldDays: 7,
      now: today,
      settlement: 'none',
    });

    expect(result.approval.candidates).toBe(1);
    expect(result.approval.eligible).toBe(0);
    expect(result.approval.heldBack).toBe(1);

    const [credit] = creditsOf(await entriesOf(scenario));
    expect(credit.status).toBe('pending');
  });
});

// ==========================================================================
describe('B3.8 — o job não implementa regra financeira', () => {
  test('5. o job não atualiza status diretamente: com o service dublado, o banco não muda', async () => {
    const plan = await makePlan({ tiers: simpleTiers() });
    const scenario = await makeScenario({ plan, pixKey: 'pix@teste' });
    await pay(scenario, { value: 100, paymentId: uid('pay') });

    // Dublê que NÃO escreve nada e devolve uma resposta plausível.
    const { payout: spied, calls } = spyPayout({
      approveInstallments: async (ids) => ({
        count: ids.length, totalAmount: '10.00', installmentIds: ids, approvedAt: new Date(),
      }),
      payApprovedInstallments: async (ids) => ({
        batchId: 'PB-DUBLE', count: ids.length, totalAmount: '10.00',
        installmentIds: ids, paidAt: new Date(),
      }),
    });

    const { job } = makeJob({ payoutImpl: spied });
    await job.run({
      scope: await scopeOf(scenario),
      settlement: 'external',
      transfer: async () => ({ id: 'transfer-fake' }),
    });

    expect(calls.approve).toHaveLength(1);

    // Toda escrita de estado mora no service. Se o service não escreveu,
    // nada escreveu — o job não tem UPDATE próprio.
    const entries = await entriesOf(scenario);
    for (const entry of entries) {
      expect(entry.status).toBe('pending');
      expect(entry.approvedAt).toBeNull();
      expect(entry.paidAt).toBeNull();
      expect(entry.payoutBatchId).toBeNull();
    }
  });

  test('11 + 12. o valor do lote vem dos lançamentos; mexer no plano depois não muda nada', async () => {
    const plan = await makePlan({ tiers: [{ fromUnit: 1, toUnit: null, percent: 10 }] });
    const scenario = await makeScenario({ plan, pixKey: 'pix@teste' });
    await pay(scenario, { value: 300, paymentId: uid('pay') });

    const credits = creditsOf(await entriesOf(scenario));
    const expected = credits.reduce((acc, c) => acc + money(c.amount), 0);
    expect(expected).toBe(30); // 10% de 300, fictício

    // Plano atual muda DEPOIS do crédito. O contrato histórico é soberano.
    await CommissionPlanTier.update(
      { percent: 99 },
      { where: { commissionPlanId: plan.id } },
    );

    const { job } = makeJob();
    const result = await job.run({
      scope: await scopeOf(scenario),
      settlement: 'external',
      transfer: async () => ({ id: 'ok' }),
    });

    const batch = result.payout.paid[0];
    expect(money(batch.totalAmount)).toBe(expected);

    const after = creditsOf(await entriesOf(scenario));
    for (const credit of after) {
      expect(money(credit.amount)).toBe(money(credits.find((c) => c.id === credit.id).amount));
      expect(money(credit.percentApplied)).toBe(10);
    }
  });

  test('13. `paidInstallments` do contrato não é tocado pelo job', async () => {
    const plan = await makePlan({ tiers: simpleTiers() });
    const scenario = await makeScenario({ plan, pixKey: 'pix@teste' });
    await pay(scenario, { value: 100, paymentId: uid('pay') });

    const before = await contractOf(scenario);

    const { job } = makeJob();
    await job.run({
      scope: await scopeOf(scenario),
      settlement: 'external',
      transfer: async () => ({ id: 'ok' }),
    });

    const after = await contractOf(scenario);
    expect(after.paidInstallments).toBe(before.paidInstallments);
    expect(after.paidInstallments).toBe(0);
  });

  test('10. o payoutBatchId vem do service — o job não gera identificador nenhum', async () => {
    const plan = await makePlan({ tiers: simpleTiers() });
    const scenario = await makeScenario({ plan, pixKey: 'pix@teste' });
    await pay(scenario, { value: 100, paymentId: uid('pay') });

    const { payout: spied } = spyPayout({
      payApprovedInstallments: async (ids, t) => {
        const real = await payout.payApprovedInstallments(ids, t);
        return { ...real, batchId: 'PB-SENTINELA-DO-SERVICE' };
      },
    });

    const { job } = makeJob({ payoutImpl: spied });
    const result = await job.run({
      scope: await scopeOf(scenario),
      settlement: 'external',
      transfer: async () => ({ id: 'ok' }),
    });

    // O job só repassa adiante o que o service devolveu.
    expect(result.payout.paid[0].batchId).toBe('PB-SENTINELA-DO-SERVICE');

    // E, no caminho real, o formato é o do service (PB-yyyyMMdd-hex12).
    const credits = creditsOf(await entriesOf(scenario));
    expect(credits[0].payoutBatchId).toMatch(/^PB-\d{8}-[0-9a-f]{12}$/);
  });
});

// ==========================================================================
describe('B3.8 — estorno (B3.6) é respeitado', () => {
  test('6. lançamento de estorno nunca entra no lote de aprovação', async () => {
    const plan = await makePlan({ tiers: simpleTiers() });
    const scenario = await makeScenario({ plan });
    const first = uid('pay');
    await pay(scenario, { value: 100, paymentId: first });
    await pay(scenario, { value: 200, paymentId: uid('pay'), paymentDate: '2026-02-10' });
    await refund(scenario, first);

    const { job } = makeJob();
    const result = await job.run({ scope: await scopeOf(scenario), settlement: 'none' });

    const entries = await entriesOf(scenario);
    const reversals = entries.filter((e) => e.entryType === 'reversal');
    expect(reversals.length).toBeGreaterThan(0);

    const approvedIds = result.approval.approved.flatMap((b) => b.installmentIds);
    for (const reversal of reversals) {
      expect(approvedIds).not.toContain(reversal.id);
      expect(reversal.status).toBe('pending'); // estorno não muda de estado aqui
    }
  });

  test('7. crédito integralmente estornado não é aprovado nem pago', async () => {
    const plan = await makePlan({ tiers: simpleTiers() });
    const scenario = await makeScenario({ plan, pixKey: 'pix@teste' });
    const target = uid('pay');
    await pay(scenario, { value: 100, paymentId: target });
    await refund(scenario, target);

    const { job } = makeJob();
    const result = await job.run({
      scope: await scopeOf(scenario),
      settlement: 'external',
      transfer: async () => ({ id: 'ok' }),
    });

    expect(result.approval.eligible).toBe(0);
    expect(result.payout.paid).toHaveLength(0);
    expect(result.ok).toBe(true);

    const credits = creditsOf(await entriesOf(scenario));
    for (const credit of credits) {
      expect(credit.status).toBe('pending');
      expect(credit.paidAt).toBeNull();
      expect(credit.payoutBatchId).toBeNull();
    }
  });

  test('crédito estornado DEPOIS da aprovação sai da fila pagável sem virar paid', async () => {
    const plan = await makePlan({ tiers: simpleTiers() });
    const scenario = await makeScenario({ plan, pixKey: 'pix@teste' });
    const target = uid('pay');
    await pay(scenario, { value: 100, paymentId: target });

    const { job } = makeJob();
    await job.run({ scope: await scopeOf(scenario), settlement: 'none' }); // aprova

    let credits = creditsOf(await entriesOf(scenario));
    expect(credits[0].status).toBe('approved');

    await refund(scenario, target); // refund append-only: crédito segue approved

    const transfer = jest.fn(async () => ({ id: 'ok' }));
    const result = await job.run({
      scope: await scopeOf(scenario),
      settlement: 'external',
      transfer,
    });

    expect(result.payout.candidates).toBe(0);
    expect(transfer).not.toHaveBeenCalled();

    credits = creditsOf(await entriesOf(scenario));
    expect(credits[0].status).toBe('approved');
    expect(credits[0].paidAt).toBeNull();
  });
});

// ==========================================================================
describe('B3.8 — repasse e liquidação externa', () => {
  test('4. o pagamento passa por payApprovedInstallments, depois da transferência', async () => {
    const plan = await makePlan({ tiers: simpleTiers() });
    const scenario = await makeScenario({ plan, pixKey: 'pix@teste' });
    await pay(scenario, { value: 100, paymentId: uid('pay') });

    const order = [];
    const { payout: spied, calls } = spyPayout({
      payApprovedInstallments: async (ids, t) => {
        order.push('pay');
        return payout.payApprovedInstallments(ids, t);
      },
    });

    const transfer = jest.fn(async () => { order.push('transfer'); return { id: 'tr_1' }; });

    const { job } = makeJob({ payoutImpl: spied });
    const result = await job.run({
      scope: await scopeOf(scenario), settlement: 'external', transfer,
    });

    expect(calls.pay).toHaveLength(1);
    expect(calls.pay[0].transaction).toBeTruthy();
    // A integração externa roda ANTES do commit contábil e FORA da transaction.
    expect(order).toEqual(['transfer', 'pay']);
    expect(transfer).toHaveBeenCalledTimes(1);

    const credits = creditsOf(await entriesOf(scenario));
    expect(credits[0].status).toBe('paid');
    expect(result.payout.paid[0].settlementResult).toEqual({ id: 'tr_1' });
  });

  test("settlement 'none' aprova, relata a fila e NÃO marca nada como paid", async () => {
    const plan = await makePlan({ tiers: simpleTiers() });
    const scenario = await makeScenario({ plan, pixKey: 'pix@teste' });
    await pay(scenario, { value: 100, paymentId: uid('pay') });

    const { job } = makeJob();
    const result = await job.run({ scope: await scopeOf(scenario), settlement: 'none' });

    expect(result.payout.candidates).toBe(1);
    expect(result.payout.paid).toHaveLength(0);
    expect(result.payout.skipped[0].reason).toBe('settlement-none');

    const credits = creditsOf(await entriesOf(scenario));
    expect(credits[0].status).toBe('approved');
    expect(credits[0].paidAt).toBeNull();
    expect(credits[0].payoutBatchId).toBeNull();
  });

  test("settlement 'external' sem função de transferência é recusado", async () => {
    const { job } = makeJob();
    await expect(job.run({ settlement: 'external' }))
      .rejects.toBeInstanceOf(CommissionJobError);
  });

  test('agente sem chave PIX não é liquidado e não vira paid', async () => {
    const plan = await makePlan({ tiers: simpleTiers() });
    const scenario = await makeScenario({ plan, pixKey: null });
    await pay(scenario, { value: 100, paymentId: uid('pay') });

    const transfer = jest.fn(async () => ({ id: 'ok' }));
    const { job, log } = makeJob();
    const result = await job.run({
      scope: await scopeOf(scenario), settlement: 'external', transfer,
    });

    expect(transfer).not.toHaveBeenCalled();
    expect(result.payout.skipped[0].reason).toBe('missing-pix-key');
    expect(log.warn).toHaveBeenCalled();

    const credits = creditsOf(await entriesOf(scenario));
    expect(credits[0].status).toBe('approved');
  });

  test('o lote nunca mistura agentes: um batchId por agente', async () => {
    const plan = await makePlan({ tiers: simpleTiers() });
    const a = await makeScenario({ plan, pixKey: 'pix@a' });
    const b = await makeScenario({ plan, pixKey: 'pix@b' });
    await pay(a, { value: 100, paymentId: uid('pay') });
    await pay(b, { value: 500, paymentId: uid('pay') });

    const transferred = [];
    const { job } = makeJob();
    const result = await job.run({
      scope: await scopeOf(a, b),
      settlement: 'external',
      transfer: async ({ agent, batch }) => {
        transferred.push({ agentId: agent.id, totalAmount: batch.totalAmount });
        return { id: `tr_${agent.id}` };
      },
    });

    expect(result.payout.paid).toHaveLength(2);
    expect(transferred).toHaveLength(2);

    const batchIds = new Set(result.payout.paid.map((p) => p.batchId));
    expect(batchIds.size).toBe(2);

    const byAgent = new Map(result.payout.paid.map((p) => [p.salesAgentId, p]));
    expect(money(byAgent.get(a.agent.id).totalAmount)).toBe(10);
    expect(money(byAgent.get(b.agent.id).totalAmount)).toBe(50);

    // Cada lançamento carimbado com o batch do SEU agente.
    const creditsA = creditsOf(await entriesOf(a));
    const creditsB = creditsOf(await entriesOf(b));
    expect(creditsA[0].payoutBatchId).toBe(byAgent.get(a.agent.id).batchId);
    expect(creditsB[0].payoutBatchId).toBe(byAgent.get(b.agent.id).batchId);
    expect(creditsA[0].payoutBatchId).not.toBe(creditsB[0].payoutBatchId);
  });
});

// ==========================================================================
describe('B3.8 — erros não são engolidos', () => {
  test('15. erro do payout aparece no resultado, no log e (com failFast) como exceção', async () => {
    const plan = await makePlan({ tiers: simpleTiers() });
    const scenario = await makeScenario({ plan });
    await pay(scenario, { value: 100, paymentId: uid('pay') });

    const { payout: spied } = spyPayout({
      approveInstallments: async () => { throw new Error('boom no service'); },
    });
    const { job, log } = makeJob({ payoutImpl: spied });
    const scope = await scopeOf(scenario);

    const result = await job.run({ scope, settlement: 'none' });

    expect(result.ok).toBe(false);
    expect(result.errors).toHaveLength(1);
    expect(result.errors[0].stage).toBe('approve');
    expect(result.errors[0].message).toBe('boom no service');
    expect(log.error).toHaveBeenCalled();

    await expect(job.run({ scope, settlement: 'none', failFast: true }))
      .rejects.toThrow(/boom no service/);
  });

  test('14. erro dentro da transaction do lote faz rollback — não existe lote meio aprovado', async () => {
    const plan = await makePlan({ tiers: simpleTiers() });
    const scenario = await makeScenario({ plan });
    await pay(scenario, { value: 100, paymentId: uid('pay') });
    await pay(scenario, { value: 200, paymentId: uid('pay'), paymentDate: '2026-02-10' });

    const { payout: spied } = spyPayout({
      // Aprova de verdade e SÓ ENTÃO falha, ainda dentro da transaction do job.
      approveInstallments: async (ids, t) => {
        await payout.approveInstallments(ids, t);
        throw new Error('falha depois do update');
      },
    });

    const { job } = makeJob({ payoutImpl: spied });
    const result = await job.run({ scope: await scopeOf(scenario), settlement: 'none' });

    expect(result.ok).toBe(false);

    const credits = creditsOf(await entriesOf(scenario));
    expect(credits).toHaveLength(2);
    for (const credit of credits) {
      expect(credit.status).toBe('pending'); // rollback limpou tudo
      expect(credit.approvedAt).toBeNull();
    }
  });

  test('16a. falha na integração externa deixa o lote em approved, nunca em paid', async () => {
    const plan = await makePlan({ tiers: simpleTiers() });
    const scenario = await makeScenario({ plan, pixKey: 'pix@teste' });
    await pay(scenario, { value: 100, paymentId: uid('pay') });

    const { payout: spied, calls } = spyPayout();
    const { job, log } = makeJob({ payoutImpl: spied });
    const result = await job.run({
      scope: await scopeOf(scenario),
      settlement: 'external',
      transfer: async () => { throw new Error('PIX recusado'); },
    });

    // Nada de commit contábil: o service de pagamento nem foi chamado.
    expect(calls.pay).toHaveLength(0);
    expect(result.ok).toBe(false);
    expect(result.errors[0].stage).toBe('transfer');
    expect(log.error).toHaveBeenCalled();

    const credits = creditsOf(await entriesOf(scenario));
    expect(credits[0].status).toBe('approved');
    expect(credits[0].paidAt).toBeNull();
    expect(credits[0].payoutBatchId).toBeNull();

    // Retry seguro: o lote volta inteiro na execução seguinte.
    const retry = await job.run({
      scope: await scopeOf(scenario),
      settlement: 'external',
      transfer: async () => ({ id: 'tr_ok' }),
    });
    expect(retry.payout.paid).toHaveLength(1);
    expect((await entriesOf(scenario)).find((e) => e.entryType === 'credit').status).toBe('paid');
  });

  test('16b. transferência OK + commit contábil falho é relatado como inconsistência explícita', async () => {
    const plan = await makePlan({ tiers: simpleTiers() });
    const scenario = await makeScenario({ plan, pixKey: 'pix@teste' });
    await pay(scenario, { value: 100, paymentId: uid('pay') });

    const { payout: spied } = spyPayout({
      payApprovedInstallments: async () => { throw new Error('commit caiu'); },
    });
    const { job, log } = makeJob({ payoutImpl: spied });

    const result = await job.run({
      scope: await scopeOf(scenario),
      settlement: 'external',
      transfer: async () => ({ id: 'tr_dinheiro_saiu' }),
    });

    expect(result.ok).toBe(false);
    const failure = result.errors[0];
    expect(failure.stage).toBe('pay');
    expect(failure.externallySettled).toBe(true);
    expect(failure.settlementResult).toEqual({ id: 'tr_dinheiro_saiu' });

    // Gritou, e gritou dizendo o que aconteceu.
    const shouted = log.error.mock.calls.map((c) => String(c[0])).join('\n');
    expect(shouted).toMatch(/INCONSIST/);

    const credits = creditsOf(await entriesOf(scenario));
    expect(credits[0].status).toBe('approved');
  });
});

// ==========================================================================
describe('B3.8 — idempotência', () => {
  test('8 + 17. reexecutar o job não repassa de novo o que já está paid', async () => {
    const plan = await makePlan({ tiers: simpleTiers() });
    const scenario = await makeScenario({ plan, pixKey: 'pix@teste' });
    await pay(scenario, { value: 100, paymentId: uid('pay') });

    const transfer = jest.fn(async () => ({ id: 'ok' }));
    const { job } = makeJob();
    const scope = await scopeOf(scenario);

    const first = await job.run({ scope, settlement: 'external', transfer });
    expect(first.payout.paid).toHaveLength(1);

    const credits = creditsOf(await entriesOf(scenario));
    const batchId = credits[0].payoutBatchId;
    const paidAt = credits[0].paidAt.getTime();

    // Mais duas voltas do cron, sem nada novo acontecendo no meio.
    const second = await job.run({ scope, settlement: 'external', transfer });
    const third = await job.run({ scope, settlement: 'external', transfer });

    expect(second.payout.candidates).toBe(0);
    expect(third.payout.candidates).toBe(0);
    expect(second.payout.paid).toHaveLength(0);
    expect(third.payout.paid).toHaveLength(0);
    expect(second.ok).toBe(true);
    expect(third.ok).toBe(true);

    // Uma transferência, um carimbo, um batch.
    expect(transfer).toHaveBeenCalledTimes(1);
    const after = creditsOf(await entriesOf(scenario));
    expect(after[0].status).toBe('paid');
    expect(after[0].payoutBatchId).toBe(batchId);
    expect(after[0].paidAt.getTime()).toBe(paidAt);
  });

  test('9. dois workers simultâneos não duplicam o repasse', async () => {
    const plan = await makePlan({ tiers: simpleTiers() });
    const scenario = await makeScenario({ plan, pixKey: 'pix@teste' });
    await pay(scenario, { value: 100, paymentId: uid('pay') });
    await pay(scenario, { value: 200, paymentId: uid('pay'), paymentDate: '2026-02-10' });

    const scope = await scopeOf(scenario);
    const workerA = makeJob().job;
    const workerB = makeJob().job;

    // 'accounting' isola a concorrência no commit contábil, que é onde os
    // locks do service atuam. (Em 'external' a corrida entre dois workers
    // atinge a transferência, que não tem estado persistido — ver a LACUNA
    // documentada no topo do job: rodar um worker só.)
    const [a, b] = await Promise.all([
      workerA.run({ scope, settlement: 'accounting' }),
      workerB.run({ scope, settlement: 'accounting' }),
    ]);

    const credits = creditsOf(await entriesOf(scenario));
    expect(credits).toHaveLength(2);
    for (const credit of credits) {
      expect(credit.status).toBe('paid');
      expect(credit.payoutBatchId).toBeTruthy();
    }

    // Cada lançamento foi pago exatamente uma vez: a soma dos lotes fechados
    // pelos dois workers cobre os 2 créditos, sem repetição.
    const paidIds = [...a.payout.paid, ...b.payout.paid].flatMap((p) => p.installmentIds);
    expect(new Set(paidIds).size).toBe(paidIds.length);
    expect(paidIds.sort()).toEqual(credits.map((c) => c.id).sort());

    // E cada crédito carrega um único batchId, o do lote que o fechou.
    const batchById = new Map();
    for (const batch of [...a.payout.paid, ...b.payout.paid]) {
      for (const id of batch.installmentIds) batchById.set(id, batch.batchId);
    }
    for (const credit of credits) {
      expect(credit.payoutBatchId).toBe(batchById.get(credit.id));
    }
  });

  test('aprovação concorrente também não duplica: o perdedor falha alto, sem escrever', async () => {
    const plan = await makePlan({ tiers: simpleTiers() });
    const scenario = await makeScenario({ plan });
    await pay(scenario, { value: 100, paymentId: uid('pay') });

    const scope = await scopeOf(scenario);
    const [a, b] = await Promise.all([
      makeJob().job.run({ scope, settlement: 'none' }),
      makeJob().job.run({ scope, settlement: 'none' }),
    ]);

    const approvedIds = [...a.approval.approved, ...b.approval.approved]
      .flatMap((batch) => batch.installmentIds);
    expect(new Set(approvedIds).size).toBe(approvedIds.length);

    const credits = creditsOf(await entriesOf(scenario));
    expect(credits[0].status).toBe('approved');
  });
});

// ==========================================================================
describe('B3.8 — gateway Asaas preservado (mesmo POST /transfers de antes)', () => {
  test('usa o mecanismo existente, com o valor do lote e a chave PIX do agente', async () => {
    const post = jest.fn(async () => ({ data: { id: 'tr_asaas_1' } }));
    const transfer = buildAsaasPixTransfer({ http: { post } });

    const result = await transfer({
      agent: { id: 'agent-1', pixKey: 'pix@agente' },
      batch: { totalAmount: '42.50', count: 3, installmentIds: ['a', 'b', 'c'] },
      referenceLabel: '2026-08',
    });

    expect(post).toHaveBeenCalledWith('/transfers', {
      value: 42.5,
      operationType: 'PIX',
      pixAddressKey: 'pix@agente',
      description: 'Comissão 2026-08',
    });
    expect(result).toEqual({ id: 'tr_asaas_1' });
  });

  test('falha do gateway sobe para o job, que a trata como transferência não realizada', async () => {
    const post = jest.fn(async () => { throw new Error('402 saldo insuficiente'); });
    const transfer = buildAsaasPixTransfer({ http: { post } });

    await expect(transfer({
      agent: { id: 'agent-1', pixKey: 'pix@agente' },
      batch: { totalAmount: '10.00', count: 1, installmentIds: ['a'] },
    })).rejects.toThrow(/saldo insuficiente/);
  });
});
