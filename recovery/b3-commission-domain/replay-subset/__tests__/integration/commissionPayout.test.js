/**
 * B3.7 — payout explícito de comissão (aprovação e pagamento).
 *
 * Exercita `commissionPayout` contra o banco local, em cima de créditos e
 * estornos gerados pelo próprio engine de B3.5/B3.6 — nem o caminho de
 * crédito nem o de estorno é alterado aqui, só consumido.
 *
 * Todos os percentuais e valores são FICTÍCIOS. As fixtures (planos, agentes,
 * tenants, signatures) são criadas pelo teste e removidas no afterAll —
 * nenhum dado pré-existente é alterado.
 */
const { loadModels } = require('../utils/sequelizeModels');
const { buildEngine } = require('../../app/services/commissionEngine');
const {
  buildPayout,
  generatePayoutBatchId,
  CommissionPayoutError,
} = require('../../app/services/commissionPayout');

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
  return `${prefix}_B37_${process.pid}_${seq}`;
}

// --------------------------------------------------------------------------
// Fixtures
// --------------------------------------------------------------------------

async function makePlan({ tiers, totalUnits = null, basis = 'billing_month' }) {
  const plan = await CommissionPlan.create(
    {
      name: `TESTE B3.7 ${uid('plan')}`,
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

async function makeScenario({ plan = null, billingCycle = 'monthly' } = {}) {
  const agent = await SalesAgent.create({
    commissionMonths: 12,
    commissionPercent: 10,
    defaultCommissionPlanId: plan ? plan.id : null,
  });
  created.agentIds.push(agent.id);

  const tenant = await Tenant.create({
    firstName: `TESTE B3.7 ${uid('tenant')}`,
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

// Roda uma operação do payout numa transação real e comita.
async function commit(fn) {
  const t = await sequelize.transaction();
  try {
    const result = await fn(t);
    await t.commit();
    return result;
  } catch (error) {
    await t.rollback();
    throw error;
  }
}

// Escopo do summary/listagens: sempre restrito ao contrato do cenário, para
// não somar lançamentos de outros testes rodando no mesmo banco.
async function scopeOf(scenario) {
  const contract = await contractOf(scenario);
  return { salesAgentCommissionId: contract.id };
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
describe('B3.7 — máquina de estados', () => {
  async function oneCredit({ value = 200, percent = 25 } = {}) {
    const plan = await makePlan({ tiers: [{ fromUnit: 1, toUnit: null, percent }] });
    const scenario = await makeScenario({ plan });
    const paymentId = uid('pay');
    await pay(scenario, { value, paymentId, paymentDate: '2026-03-05' });
    const [credit] = creditsOf(await entriesOf(scenario));
    return { scenario, credit, paymentId };
  }

  test('1. pending → approved', async () => {
    const { credit } = await oneCredit();
    expect(credit.status).toBe('pending');
    expect(credit.approvedAt).toBeNull();

    const result = await commit((t) => payout.approveInstallments([credit.id], t));

    expect(result.count).toBe(1);
    expect(money(result.totalAmount)).toBe(50);

    const after = await SalesAgentCommissionInstallment.findByPk(credit.id);
    expect(after.status).toBe('approved');
    expect(after.approvedAt).not.toBeNull();
    // aprovar não é pagar
    expect(after.paidAt).toBeNull();
    expect(after.payoutBatchId).toBeNull();
  });

  test('2 + 6 + 7. approved → paid grava paidAt e payoutBatchId', async () => {
    const { credit } = await oneCredit();
    await commit((t) => payout.approveInstallments([credit.id], t));

    const before = new Date();
    const batch = await commit((t) => payout.payApprovedInstallments([credit.id], t));

    expect(batch.count).toBe(1);
    expect(batch.installmentIds).toEqual([credit.id]);

    const after = await SalesAgentCommissionInstallment.findByPk(credit.id);
    expect(after.status).toBe('paid');

    // 6. paidAt registra o momento do pagamento
    expect(after.paidAt).not.toBeNull();
    expect(new Date(after.paidAt).getTime()).toBeGreaterThanOrEqual(before.getTime() - 1000);

    // 7. payoutBatchId gerado e gravado
    expect(after.payoutBatchId).toBe(batch.batchId);
    expect(after.payoutBatchId).toMatch(/^PB-\d{8}-[0-9a-f]{12}$/);
  });

  test('3. pending → paid é rejeitado', async () => {
    const { credit } = await oneCredit();

    await expect(commit((t) => payout.payApprovedInstallments([credit.id], t)))
      .rejects.toThrow(/está 'pending'/);

    const after = await SalesAgentCommissionInstallment.findByPk(credit.id);
    expect(after.status).toBe('pending');
    expect(after.paidAt).toBeNull();
    expect(after.payoutBatchId).toBeNull();
  });

  test('4. paid → approved é rejeitado', async () => {
    const { credit } = await oneCredit();
    await commit((t) => payout.approveInstallments([credit.id], t));
    const batch = await commit((t) => payout.payApprovedInstallments([credit.id], t));

    await expect(commit((t) => payout.approveInstallments([credit.id], t)))
      .rejects.toThrow(/está 'paid'/);

    const after = await SalesAgentCommissionInstallment.findByPk(credit.id);
    expect(after.status).toBe('paid');
    expect(after.payoutBatchId).toBe(batch.batchId);
  });

  test('paid → paid (reentrega do mesmo lote) é rejeitado', async () => {
    const { credit } = await oneCredit();
    await commit((t) => payout.approveInstallments([credit.id], t));
    const batch = await commit((t) => payout.payApprovedInstallments([credit.id], t));

    await expect(commit((t) => payout.payApprovedInstallments([credit.id], t)))
      .rejects.toThrow(/está 'paid'/);

    const after = await SalesAgentCommissionInstallment.findByPk(credit.id);
    expect(after.payoutBatchId).toBe(batch.batchId);
  });

  test('approved → pending não existe: o service não expõe volta de estado', async () => {
    expect(Object.keys(payout)).toEqual(
      expect.not.arrayContaining(['unapproveInstallments', 'revertInstallments']),
    );
    // e aprovar de novo um já aprovado é erro, não no-op silencioso
    const { credit } = await oneCredit();
    await commit((t) => payout.approveInstallments([credit.id], t));
    await expect(commit((t) => payout.approveInstallments([credit.id], t)))
      .rejects.toThrow(/está 'approved'/);
  });

  test('5. cancelled → paid é rejeitado (e cancelled → approved também)', async () => {
    const { scenario, credit, paymentId } = await oneCredit();
    await commit((t) => payout.approveInstallments([credit.id], t));

    // refund transforma o crédito aprovado em economicamente nulo
    await refund(scenario, paymentId);
    await commit((t) => payout.cancelReversedInstallments([credit.id], t));

    expect((await SalesAgentCommissionInstallment.findByPk(credit.id)).status).toBe('cancelled');

    await expect(commit((t) => payout.payApprovedInstallments([credit.id], t)))
      .rejects.toThrow(/está 'cancelled'/);
    await expect(commit((t) => payout.approveInstallments([credit.id], t)))
      .rejects.toThrow(/está 'cancelled'/);

    expect((await SalesAgentCommissionInstallment.findByPk(credit.id)).status).toBe('cancelled');
  });

  test('paid não é cancelado por este mecanismo', async () => {
    const { scenario, credit, paymentId } = await oneCredit();
    await commit((t) => payout.approveInstallments([credit.id], t));
    await commit((t) => payout.payApprovedInstallments([credit.id], t));
    await refund(scenario, paymentId);

    await expect(commit((t) => payout.cancelReversedInstallments([credit.id], t)))
      .rejects.toThrow(/está 'paid'/);

    expect((await SalesAgentCommissionInstallment.findByPk(credit.id)).status).toBe('paid');
  });

  test('reversal não é aprovado nem pago', async () => {
    const { scenario, credit, paymentId } = await oneCredit();
    await refund(scenario, paymentId);

    const [reversal] = (await entriesOf(scenario)).filter((e) => e.entryType === 'reversal');
    expect(reversal.reversalOfId).toBe(credit.id);

    await expect(commit((t) => payout.approveInstallments([reversal.id], t)))
      .rejects.toThrow(/estorno não é repassado/);
  });

  test('id inexistente derruba o lote', async () => {
    const { credit } = await oneCredit();
    const ghost = '00000000-0000-4000-8000-000000000000';

    await expect(commit((t) => payout.approveInstallments([credit.id, ghost], t)))
      .rejects.toThrow(/inexistente/);

    expect((await SalesAgentCommissionInstallment.findByPk(credit.id)).status).toBe('pending');
  });

  test('transaction é obrigatória', async () => {
    const { credit } = await oneCredit();
    await expect(payout.approveInstallments([credit.id], null))
      .rejects.toThrow(/transaction é obrigatória/);
    const t = await sequelize.transaction();
    await expect(payout.payApprovedInstallments([], t))
      .rejects.toThrow(/nenhum lançamento informado/);
    await t.rollback();
  });
});

// ==========================================================================
describe('B3.7 — lote de repasse', () => {
  test('8 + 9. vários lançamentos recebem o MESMO batchId e o total é a soma dos amount',
    async () => {
      const plan = await makePlan({
        totalUnits: null,
        tiers: [
          { fromUnit: 1, toUnit: 3, percent: 30 },
          { fromUnit: 4, toUnit: null, percent: 10 },
        ],
      });
      const scenario = await makeScenario({ plan });

      await pay(scenario, { value: 100, paymentId: uid('pay'), paymentDate: '2026-01-10' });
      await pay(scenario, { value: 200, paymentId: uid('pay'), paymentDate: '2026-02-10' });
      await pay(scenario, { value: 300, paymentId: uid('pay'), paymentDate: '2026-03-10' });

      const credits = creditsOf(await entriesOf(scenario));
      expect(credits.length).toBe(3);

      const ids = credits.map((c) => c.id);
      const expectedTotal = credits.reduce((acc, c) => acc + money(c.amount), 0);

      await commit((t) => payout.approveInstallments(ids, t));
      const batch = await commit((t) => payout.payApprovedInstallments(ids, t));

      // 9. total do lote = soma dos amount gravados
      expect(money(batch.totalAmount)).toBe(money(expectedTotal));
      expect(batch.count).toBe(3);

      // 8. mesmo payoutBatchId em todas as linhas do lote
      const after = await SalesAgentCommissionInstallment.findAll({ where: { id: ids } });
      const batchIds = new Set(after.map((i) => i.payoutBatchId));
      expect(batchIds.size).toBe(1);
      expect([...batchIds][0]).toBe(batch.batchId);
      expect(after.every((i) => i.status === 'paid')).toBe(true);
      expect(after.every((i) => i.paidAt !== null)).toBe(true);
    });

  test('lotes distintos recebem batchIds distintos', async () => {
    const plan = await makePlan({ tiers: [{ fromUnit: 1, toUnit: null, percent: 20 }] });
    const scenario = await makeScenario({ plan });

    await pay(scenario, { value: 100, paymentId: uid('pay'), paymentDate: '2026-01-10' });
    await pay(scenario, { value: 100, paymentId: uid('pay'), paymentDate: '2026-02-10' });

    const [a, b] = creditsOf(await entriesOf(scenario));

    await commit((t) => payout.approveInstallments([a.id, b.id], t));
    const batch1 = await commit((t) => payout.payApprovedInstallments([a.id], t));
    const batch2 = await commit((t) => payout.payApprovedInstallments([b.id], t));

    expect(batch1.batchId).not.toBe(batch2.batchId);
  });

  test('formato do payoutBatchId é PB-<yyyyMMdd>-<12 hex> e não colide', () => {
    const ids = new Set();
    for (let i = 0; i < 500; i += 1) {
      const id = generatePayoutBatchId();
      expect(id).toMatch(/^PB-\d{8}-[0-9a-f]{12}$/);
      ids.add(id);
    }
    expect(ids.size).toBe(500);
  });

  test('17. um lançamento inválido impede o pagamento PARCIAL do lote', async () => {
    const plan = await makePlan({ tiers: [{ fromUnit: 1, toUnit: null, percent: 20 }] });
    const scenario = await makeScenario({ plan });

    await pay(scenario, { value: 100, paymentId: uid('pay'), paymentDate: '2026-01-10' });
    await pay(scenario, { value: 100, paymentId: uid('pay'), paymentDate: '2026-02-10' });

    const [ok, bad] = creditsOf(await entriesOf(scenario));

    // só o primeiro é aprovado: o segundo continua pending
    await commit((t) => payout.approveInstallments([ok.id], t));

    await expect(commit((t) => payout.payApprovedInstallments([ok.id, bad.id], t)))
      .rejects.toThrow(/está 'pending'/);

    // nada foi pago — nem o que era elegível
    const after = await SalesAgentCommissionInstallment.findAll({ where: { id: [ok.id, bad.id] } });
    expect(after.every((i) => i.status !== 'paid')).toBe(true);
    expect(after.every((i) => i.paidAt === null)).toBe(true);
    expect(after.every((i) => i.payoutBatchId === null)).toBe(true);
  });

  test('aprovação em lote também é tudo-ou-nada', async () => {
    const plan = await makePlan({ tiers: [{ fromUnit: 1, toUnit: null, percent: 20 }] });
    const scenario = await makeScenario({ plan });

    await pay(scenario, { value: 100, paymentId: uid('pay'), paymentDate: '2026-01-10' });
    await pay(scenario, { value: 100, paymentId: uid('pay'), paymentDate: '2026-02-10' });

    const [a, b] = creditsOf(await entriesOf(scenario));
    await commit((t) => payout.approveInstallments([a.id], t));

    await expect(commit((t) => payout.approveInstallments([a.id, b.id], t)))
      .rejects.toThrow(/está 'approved'/);

    expect((await SalesAgentCommissionInstallment.findByPk(b.id)).status).toBe('pending');
  });
});

// ==========================================================================
describe('B3.7 — o contrato histórico é soberano', () => {
  test('10 + 11. o valor pago vem de installment.amount; plano alterado depois não muda nada',
    async () => {
      const plan = await makePlan({ tiers: [{ fromUnit: 1, toUnit: null, percent: 25 }] });
      const scenario = await makeScenario({ plan });

      await pay(scenario, { value: 200, paymentId: uid('pay'), paymentDate: '2026-03-05' });

      const [credit] = creditsOf(await entriesOf(scenario));
      expect(money(credit.amount)).toBe(50);

      // 11. o mundo muda DEPOIS do crédito: plano, faixa e agente
      await CommissionPlanTier.update(
        { percent: 90 },
        { where: { commissionPlanId: plan.id } },
      );
      await SalesAgent.update(
        { commissionPercent: 90, commissionMonths: 99 },
        { where: { id: scenario.agent.id } },
      );
      const contractBefore = await contractOf(scenario);
      await contractBefore.update({ percent: 90, commissionMonths: 99 });

      await commit((t) => payout.approveInstallments([credit.id], t));
      const batch = await commit((t) => payout.payApprovedInstallments([credit.id], t));

      // 10. o lote paga exatamente o amount gravado
      expect(money(batch.totalAmount)).toBe(50);

      const after = await SalesAgentCommissionInstallment.findByPk(credit.id);
      expect(money(after.amount)).toBe(50);
      expect(money(after.baseAmount)).toBe(200);
      expect(money(after.percentApplied)).toBe(25);
    });

  test('18 + 19. payout não toca em paidInstallments nem na memória de cálculo do crédito',
    async () => {
      const plan = await makePlan({ tiers: [{ fromUnit: 1, toUnit: null, percent: 40 }] });
      const scenario = await makeScenario({ plan });

      await pay(scenario, { value: 150, paymentId: uid('pay'), paymentDate: '2026-04-05' });

      const contractBefore = (await contractOf(scenario)).toJSON();
      const [credit] = creditsOf(await entriesOf(scenario));
      const creditBefore = credit.toJSON();

      await commit((t) => payout.approveInstallments([credit.id], t));
      await commit((t) => payout.payApprovedInstallments([credit.id], t));

      // 18. contador legado intocado (e o contrato inteiro, aliás)
      const contractAfter = (await contractOf(scenario)).toJSON();
      expect(contractAfter.paidInstallments).toBe(contractBefore.paidInstallments);
      expect(contractAfter.totalInstallments).toBe(contractBefore.totalInstallments);
      expect(contractAfter.status).toBe(contractBefore.status);

      // 19. a memória gravada pelo engine continua byte a byte a mesma; o
      // payout só mexe no estado financeiro (status/approvedAt/paidAt/batch).
      const creditAfter = (await SalesAgentCommissionInstallment.findByPk(credit.id)).toJSON();
      const FINANCIAL_STATE = ['status', 'approvedAt', 'paidAt', 'payoutBatchId', 'updatedAt'];
      for (const key of Object.keys(creditBefore)) {
        if (FINANCIAL_STATE.includes(key)) continue;
        expect({ [key]: creditAfter[key] }).toEqual({ [key]: creditBefore[key] });
      }
    });
});

// ==========================================================================
describe('B3.7 — estorno antes do repasse', () => {
  test('12 + Caso A. credit pending estornado não entra no payout', async () => {
    const plan = await makePlan({ tiers: [{ fromUnit: 1, toUnit: null, percent: 25 }] });
    const scenario = await makeScenario({ plan });
    const paymentId = uid('pay');

    await pay(scenario, { value: 200, paymentId, paymentDate: '2026-05-05' });
    const [credit] = creditsOf(await entriesOf(scenario));

    await refund(scenario, paymentId);

    // o crédito segue 'pending' (o refund é append-only e não o toca)...
    const stillPending = await SalesAgentCommissionInstallment.findByPk(credit.id);
    expect(stillPending.status).toBe('pending');

    // ...mas não é elegível: o líquido de estornos zerou
    const approvable = await payout.listApprovableInstallments(await scopeOf(scenario));
    expect(approvable.map((i) => i.id)).not.toContain(credit.id);

    await expect(commit((t) => payout.approveInstallments([credit.id], t)))
      .rejects.toThrow(/foi estornado/);

    // e o histórico continua inteiro: crédito + estorno
    const entries = await entriesOf(scenario);
    expect(entries).toHaveLength(2);
  });

  test('13 + Caso B. refund depois de approved: sai da fila via cancelamento explícito',
    async () => {
      const plan = await makePlan({ tiers: [{ fromUnit: 1, toUnit: null, percent: 25 }] });
      const scenario = await makeScenario({ plan });
      const paymentId = uid('pay');

      await pay(scenario, { value: 200, paymentId, paymentDate: '2026-05-05' });
      const [credit] = creditsOf(await entriesOf(scenario));

      await commit((t) => payout.approveInstallments([credit.id], t));
      await refund(scenario, paymentId);

      // o refund NÃO volta o crédito para pending em silêncio
      expect((await SalesAgentCommissionInstallment.findByPk(credit.id)).status).toBe('approved');

      // mas ele já não é pagável, e a fila de repasse não o enxerga
      const payable = await payout.listPayableInstallments(await scopeOf(scenario));
      expect(payable.map((i) => i.id)).not.toContain(credit.id);
      await expect(commit((t) => payout.payApprovedInstallments([credit.id], t)))
        .rejects.toThrow(/foi estornado/);

      // a transição coerente é explícita: approved → cancelled
      const result = await commit((t) => payout.cancelReversedInstallments([credit.id], t));
      expect(result.count).toBe(1);

      const after = await SalesAgentCommissionInstallment.findByPk(credit.id);
      expect(after.status).toBe('cancelled');
      expect(after.paidAt).toBeNull();
      expect(after.payoutBatchId).toBeNull();
      // valor e memória preservados
      expect(money(after.amount)).toBe(50);
    });

  test('crédito não estornado não pode ser cancelado por este mecanismo', async () => {
    const plan = await makePlan({ tiers: [{ fromUnit: 1, toUnit: null, percent: 25 }] });
    const scenario = await makeScenario({ plan });
    await pay(scenario, { value: 200, paymentId: uid('pay'), paymentDate: '2026-05-05' });
    const [credit] = creditsOf(await entriesOf(scenario));

    await expect(commit((t) => payout.cancelReversedInstallments([credit.id], t)))
      .rejects.toThrow(/não foi estornado/);

    expect((await SalesAgentCommissionInstallment.findByPk(credit.id)).status).toBe('pending');
  });

  test('14 + Caso C. refund depois de paid gera reversal sem apagar o paid — vira pendência',
    async () => {
      const plan = await makePlan({ tiers: [{ fromUnit: 1, toUnit: null, percent: 25 }] });
      const scenario = await makeScenario({ plan });
      const paymentId = uid('pay');

      await pay(scenario, { value: 200, paymentId, paymentDate: '2026-06-05' });
      const [credit] = creditsOf(await entriesOf(scenario));

      await commit((t) => payout.approveInstallments([credit.id], t));
      const batch = await commit((t) => payout.payApprovedInstallments([credit.id], t));

      await refund(scenario, paymentId);

      // o pagamento não é desfeito
      const after = await SalesAgentCommissionInstallment.findByPk(credit.id);
      expect(after.status).toBe('paid');
      expect(after.paidAt).not.toBeNull();
      expect(after.payoutBatchId).toBe(batch.batchId);
      expect(money(after.amount)).toBe(50);

      // o estorno existe como histórico
      const entries = await entriesOf(scenario);
      const reversals = entries.filter((e) => e.entryType === 'reversal');
      expect(reversals).toHaveLength(1);
      expect(reversals[0].reversalOfId).toBe(credit.id);
      expect(money(reversals[0].amount)).toBe(-50);

      // e sobra explicitamente como pendência de ajuste financeiro
      const scope = await scopeOf(scenario);
      const pendencies = await payout.listPaidReversedInstallments(scope);
      expect(pendencies.map((p) => p.installmentId)).toContain(credit.id);
      expect(money(pendencies[0].reversedAmount)).toBe(-50);
      expect(pendencies[0].payoutBatchId).toBe(batch.batchId);

      const summary = await payout.summarizeInstallments(scope);
      expect(money(summary.paidAmount)).toBe(50);
      expect(money(summary.reversedPaidAmount)).toBe(50);
      // nenhum débito automático foi inventado
      expect(money(summary.totalAmount)).toBe(0);
    });
});

// ==========================================================================
describe('B3.7 — transação e concorrência', () => {
  test('16. todos os updates usam a transaction recebida — rollback não deixa rastro',
    async () => {
      const plan = await makePlan({ tiers: [{ fromUnit: 1, toUnit: null, percent: 25 }] });
      const scenario = await makeScenario({ plan });
      await pay(scenario, { value: 200, paymentId: uid('pay'), paymentDate: '2026-07-05' });
      const [credit] = creditsOf(await entriesOf(scenario));

      // aprovação desfeita pelo rollback do caller
      const t1 = await sequelize.transaction();
      await payout.approveInstallments([credit.id], t1);
      await t1.rollback();

      let after = await SalesAgentCommissionInstallment.findByPk(credit.id);
      expect(after.status).toBe('pending');
      expect(after.approvedAt).toBeNull();

      // pagamento idem
      await commit((t) => payout.approveInstallments([credit.id], t));

      const t2 = await sequelize.transaction();
      const batch = await payout.payApprovedInstallments([credit.id], t2);
      expect(batch.batchId).toBeTruthy();
      await t2.rollback();

      after = await SalesAgentCommissionInstallment.findByPk(credit.id);
      expect(after.status).toBe('approved');
      expect(after.paidAt).toBeNull();
      expect(after.payoutBatchId).toBeNull();

      // e o cancelamento também
      const paymentId2 = uid('pay');
      await pay(scenario, { value: 100, paymentId: paymentId2, paymentDate: '2026-08-05' });
      await refund(scenario, paymentId2);
      const reversed = creditsOf(await entriesOf(scenario))
        .find((c) => c.paymentId === paymentId2);

      const t3 = await sequelize.transaction();
      await payout.cancelReversedInstallments([reversed.id], t3);
      await t3.rollback();

      expect((await SalesAgentCommissionInstallment.findByPk(reversed.id)).status)
        .toBe('pending');
    });

  test('15. dois processos concorrentes não pagam o mesmo lançamento duas vezes', async () => {
    const plan = await makePlan({ tiers: [{ fromUnit: 1, toUnit: null, percent: 25 }] });
    const scenario = await makeScenario({ plan });
    await pay(scenario, { value: 400, paymentId: uid('pay'), paymentDate: '2026-09-05' });
    const [credit] = creditsOf(await entriesOf(scenario));

    await commit((t) => payout.approveInstallments([credit.id], t));

    const t1 = await sequelize.transaction();
    const t2 = await sequelize.transaction();

    // Processo 1 pega o lock e fecha o lote, mas ainda não commitou.
    const batch1 = await payout.payApprovedInstallments([credit.id], t1);

    // Processo 2 entra na mesma linha: bloqueia no SELECT ... FOR UPDATE.
    const race = payout.payApprovedInstallments([credit.id], t2)
      .then(() => null, (error) => error);

    // Dá tempo do processo 2 realmente enfileirar no lock antes do commit.
    await new Promise((resolve) => setTimeout(resolve, 500));
    await t1.commit();

    const error = await race;
    await t2.rollback();

    // o segundo processo encontra o estado já alterado e não repete o pagamento
    expect(error).toBeInstanceOf(CommissionPayoutError);
    expect(error.message).toMatch(/está 'paid'/);

    const after = await SalesAgentCommissionInstallment.findByPk(credit.id);
    expect(after.status).toBe('paid');
    expect(after.payoutBatchId).toBe(batch1.batchId);
  });
});

// ==========================================================================
describe('B3.7 — totais derivados (sem contador mutável)', () => {
  test('10. pendingAmount / approvedAmount / paidAmount / totalAmount saem dos lançamentos',
    async () => {
      const plan = await makePlan({ tiers: [{ fromUnit: 1, toUnit: null, percent: 50 }] });
      const scenario = await makeScenario({ plan });

      await pay(scenario, { value: 100, paymentId: uid('pay'), paymentDate: '2026-01-10' }); // 50
      await pay(scenario, { value: 200, paymentId: uid('pay'), paymentDate: '2026-02-10' }); // 100
      await pay(scenario, { value: 300, paymentId: uid('pay'), paymentDate: '2026-03-10' }); // 150

      const [a, b, c] = creditsOf(await entriesOf(scenario));
      const scope = await scopeOf(scenario);

      let summary = await payout.summarizeInstallments(scope);
      expect(money(summary.pendingAmount)).toBe(300);
      expect(money(summary.approvedAmount)).toBe(0);
      expect(money(summary.paidAmount)).toBe(0);
      expect(money(summary.totalAmount)).toBe(300);

      await commit((t) => payout.approveInstallments([b.id, c.id], t));
      summary = await payout.summarizeInstallments(scope);
      expect(money(summary.pendingAmount)).toBe(50);
      expect(money(summary.approvedAmount)).toBe(250);

      await commit((t) => payout.payApprovedInstallments([c.id], t));
      summary = await payout.summarizeInstallments(scope);
      expect(money(summary.pendingAmount)).toBe(50);
      expect(money(summary.approvedAmount)).toBe(100);
      expect(money(summary.paidAmount)).toBe(150);
      expect(money(summary.totalAmount)).toBe(300);

      expect(a.status).toBe('pending');
    });

  test('estorno reduz o pendente sem contador: o líquido é derivado', async () => {
    const plan = await makePlan({ tiers: [{ fromUnit: 1, toUnit: null, percent: 50 }] });
    const scenario = await makeScenario({ plan });
    const p1 = uid('pay');

    await pay(scenario, { value: 100, paymentId: p1, paymentDate: '2026-01-10' }); // 50
    await pay(scenario, { value: 200, paymentId: uid('pay'), paymentDate: '2026-02-10' }); // 100

    const scope = await scopeOf(scenario);
    expect(money((await payout.summarizeInstallments(scope)).pendingAmount)).toBe(150);

    await refund(scenario, p1);

    const summary = await payout.summarizeInstallments(scope);
    expect(money(summary.pendingAmount)).toBe(100);
    expect(money(summary.reversedAmount)).toBe(-50);
    expect(money(summary.totalAmount)).toBe(100);

    const approvable = await payout.listApprovableInstallments(scope);
    expect(approvable).toHaveLength(1);
  });
});
