/**
 * B3.4 — Schema + models do modelo de comissão por plano/faixas.
 *
 * Valida SÓ estrutura e relacionamentos. O commissionEngine não é exercitado
 * aqui: ele ainda não conhece planos.
 *
 * Os dados criados são fictícios e removidos no afterAll.
 */
const { loadModels } = require('../utils/sequelizeModels');

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

jest.setTimeout(30000);

const created = {
  installmentIds: [],
  commissionIds: [],
  planIds: [],
  agentIds: [],
};

let tenantId;
let signatureId;
let plan;
let directContract;
let overrideContract;

// O Sequelize embrulha a violação de unique do MySQL numa
// SequelizeUniqueConstraintError cuja message é só "Validation error" —
// por isso a asserção é pelo nome do erro, não pelo texto.
async function expectUniqueViolation(promise) {
  await expect(promise).rejects.toHaveProperty('name', 'SequelizeUniqueConstraintError');
}

async function describeTable(table) {
  const [rows] = await sequelize.query(`SHOW COLUMNS FROM \`${table}\``);
  return rows.reduce((acc, r) => ({ ...acc, [r.Field]: r }), {});
}

beforeAll(async () => {
  await sequelize.authenticate();

  const signature = await Signature.findOne({ order: [['id', 'ASC']] });
  if (!signature) throw new Error('Nenhuma signature no banco local para usar de fixture');
  signatureId = signature.id;
  tenantId = signature.tenantId;

  const tenant = await Tenant.findByPk(tenantId);
  if (!tenant) throw new Error('Tenant da signature não encontrado');
});

afterAll(async () => {
  // Ordem importa: reversal → credit (FK RESTRICT), override → direct (FK RESTRICT)
  await SalesAgentCommissionInstallment.destroy({
    where: { id: created.installmentIds, entryType: 'reversal' },
  });
  await SalesAgentCommissionInstallment.destroy({ where: { id: created.installmentIds } });
  await SalesAgentCommission.destroy({ where: { id: created.commissionIds, kind: 'override' } });
  await SalesAgentCommission.destroy({ where: { id: created.commissionIds } });
  await SalesAgent.update(
    { defaultCommissionPlanId: null },
    { where: { id: created.agentIds } },
  );
  await SalesAgent.destroy({ where: { id: created.agentIds } });
  await CommissionPlan.destroy({ where: { id: created.planIds } });
  await sequelize.close();
});

describe('B3.4 — schema', () => {
  test('1. models carregam e a conexão sobe', async () => {
    expect(CommissionPlan).toBeDefined();
    expect(CommissionPlanTier).toBeDefined();
    expect(SalesAgentCommissionTerm).toBeDefined();
    await expect(sequelize.authenticate()).resolves.toBeUndefined();
  });

  test('2. sales_agents recebe a FK defaultCommissionPlanId', async () => {
    const cols = await describeTable('sales_agents');
    expect(cols.defaultCommissionPlanId).toBeDefined();
    expect(cols.defaultCommissionPlanId.Null).toBe('YES');

    const [fks] = await sequelize.query(`
      SELECT REFERENCED_TABLE_NAME AS ref
        FROM information_schema.KEY_COLUMN_USAGE
       WHERE TABLE_SCHEMA = DATABASE()
         AND TABLE_NAME = 'sales_agents'
         AND COLUMN_NAME = 'defaultCommissionPlanId'
         AND REFERENCED_TABLE_NAME IS NOT NULL
    `);
    expect(fks.map((f) => f.ref)).toContain('commission_plans');
  });

  test('10. ENUMs estão como a arquitetura pede', async () => {
    const plans = await describeTable('commission_plans');
    expect(plans.basis.Type).toBe("enum('billing_month','payment')");
    expect(plans.tierBasis.Type).toBe("enum('sequence','volume')");

    const commissions = await describeTable('sales_agent_commissions');
    expect(commissions.status.Type).toBe("enum('active','suspended','completed','cancelled')");
    expect(commissions.kind.Type).toBe("enum('direct','override')");
    expect(commissions.basis.Type).toBe("enum('billing_month','payment')");
    expect(commissions.tierBasis.Type).toBe("enum('sequence','volume')");

    const installments = await describeTable('sales_agent_commission_installments');
    expect(installments.status.Type).toBe("enum('pending','approved','paid','cancelled')");
    expect(installments.entryType.Type).toBe("enum('credit','reversal')");

    // paidAt existe UMA vez só (a migration original declarava duas)
    expect(Object.keys(installments).filter((c) => c === 'paidAt')).toHaveLength(1);
    expect(installments.paidAt.Null).toBe('YES');
  });

  test('campos aposentados do contrato viraram opcionais', async () => {
    const cols = await describeTable('sales_agent_commissions');
    for (const field of ['percent', 'endDate', 'commissionMonths', 'totalInstallments']) {
      expect(cols[field].Null).toBe('YES');
    }
  });
});

describe('B3.4 — plano, contrato e terms', () => {
  test('3. cria um CommissionPlan com três faixas', async () => {
    plan = await CommissionPlan.create(
      {
        name: 'TESTE B3.4 — escalonado',
        description: 'plano fictício de teste',
        basis: 'billing_month',
        tierBasis: 'sequence',
        totalUnits: 12,
        isActive: true,
        tiers: [
          { tierOrder: 1, fromUnit: 1, toUnit: 3, percent: 40.0 },
          { tierOrder: 2, fromUnit: 4, toUnit: 12, percent: 20.0 },
          { tierOrder: 3, fromUnit: 13, toUnit: null, percent: 10.0 },
        ],
      },
      { include: [{ association: 'tiers' }] },
    );
    created.planIds.push(plan.id);

    const reloaded = await CommissionPlan.findByPk(plan.id, {
      include: [{ association: 'tiers' }],
    });
    expect(reloaded.tiers).toHaveLength(3);
    expect(reloaded.basis).toBe('billing_month');
    expect(reloaded.tiers.find((t) => t.tierOrder === 3).toUnit).toBeNull();
  });

  test('plan tiers têm unique (commissionPlanId, tierOrder)', async () => {
    await expectUniqueViolation(
      CommissionPlanTier.create({
        commissionPlanId: plan.id,
        tierOrder: 1,
        fromUnit: 1,
        toUnit: 2,
        percent: 99.0,
      }),
    );
  });

  test('4. cria o agente, aponta o plano padrão e fecha o contrato com terms', async () => {
    const agent = await SalesAgent.create({
      commissionMonths: 12,
      defaultCommissionPlanId: plan.id,
    });
    created.agentIds.push(agent.id);

    const withPlan = await SalesAgent.findByPk(agent.id, {
      include: [{ association: 'defaultCommissionPlan', include: [{ association: 'tiers' }] }],
    });
    expect(withPlan.defaultCommissionPlan.id).toBe(plan.id);
    expect(withPlan.defaultCommissionPlan.tiers).toHaveLength(3);

    // Snapshot das faixas no momento da contratação
    directContract = await SalesAgentCommission.create(
      {
        salesAgentId: agent.id,
        tenantId,
        signatureId,
        kind: 'direct',
        commissionPlanId: plan.id,
        basis: plan.basis,
        tierBasis: plan.tierBasis,
        totalUnits: plan.totalUnits,
        startDate: '2026-09-01',
        status: 'active',
        terms: withPlan.defaultCommissionPlan.tiers.map((t) => ({
          tierOrder: t.tierOrder,
          fromUnit: t.fromUnit,
          toUnit: t.toUnit,
          percent: t.percent,
        })),
      },
      { include: [{ association: 'terms' }] },
    );
    created.commissionIds.push(directContract.id);

    const reloaded = await SalesAgentCommission.findByPk(directContract.id, {
      include: [{ association: 'terms' }, { association: 'commissionPlan' }],
    });
    expect(reloaded.terms).toHaveLength(3);
    expect(reloaded.commissionPlan.id).toBe(plan.id);
    // O contrato não depende dos campos aposentados
    expect(reloaded.percent).toBeNull();
    expect(reloaded.endDate).toBeNull();
    expect(reloaded.commissionMonths).toBeNull();
    expect(reloaded.totalInstallments).toBeNull();
  });

  test('5. os terms são independentes do plano original', async () => {
    // Muda o plano depois de contratado
    await CommissionPlanTier.update(
      { percent: 1.0 },
      { where: { commissionPlanId: plan.id, tierOrder: 1 } },
    );
    await plan.update({ isActive: false, totalUnits: 999 });

    const terms = await SalesAgentCommissionTerm.findAll({
      where: { salesAgentCommissionId: directContract.id },
      order: [['tierOrder', 'ASC']],
    });
    expect(parseFloat(terms[0].percent)).toBe(40.0);

    const contract = await SalesAgentCommission.findByPk(directContract.id);
    expect(contract.totalUnits).toBe(12);
  });
});

describe('B3.4 — unicidade do contrato', () => {
  test('6. mesmo agent + tenant + signature + kind não duplica', async () => {
    await expectUniqueViolation(
      SalesAgentCommission.create({
        salesAgentId: created.agentIds[0],
        tenantId,
        signatureId,
        kind: 'direct',
        startDate: '2026-09-01',
        status: 'active',
      }),
    );
  });

  test('7. direct e override coexistem para o mesmo tenant/signature', async () => {
    overrideContract = await SalesAgentCommission.create(
      {
        salesAgentId: created.agentIds[0],
        tenantId,
        signatureId,
        kind: 'override',
        parentCommissionId: directContract.id,
        commissionPlanId: plan.id,
        basis: 'billing_month',
        tierBasis: 'sequence',
        totalUnits: 12,
        startDate: '2026-09-01',
        status: 'active',
        terms: [{ tierOrder: 1, fromUnit: 1, toUnit: null, percent: 5.0 }],
      },
      { include: [{ association: 'terms' }] },
    );
    created.commissionIds.push(overrideContract.id);

    const both = await SalesAgentCommission.findAll({
      where: { salesAgentId: created.agentIds[0], tenantId, signatureId },
    });
    expect(both.map((c) => c.kind).sort()).toEqual(['direct', 'override']);

    const child = await SalesAgentCommission.findByPk(overrideContract.id, {
      include: [{ association: 'parentCommission' }],
    });
    expect(child.parentCommission.id).toBe(directContract.id);
  });
});

describe('B3.4 — lançamentos', () => {
  const paymentId = 'pay_TESTE_B34_0001';
  let directTerm;
  let overrideTerm;
  let creditEntry;

  test('8. mesmo paymentId em contratos/terms diferentes é permitido', async () => {
    [directTerm] = await SalesAgentCommissionTerm.findAll({
      where: { salesAgentCommissionId: directContract.id, tierOrder: 1 },
    });
    [overrideTerm] = await SalesAgentCommissionTerm.findAll({
      where: { salesAgentCommissionId: overrideContract.id, tierOrder: 1 },
    });

    const base = {
      installmentNumber: 1,
      paymentId,
      referenceMonth: '2026-09',
      dueDate: '2026-09-10',
      paymentDate: new Date('2026-09-05'),
      billingCycle: 'monthly',
      unitFrom: 1,
      unitTo: 1,
      unitsCovered: 1,
      baseAmount: 100.0,
      status: 'pending',
      entryType: 'credit',
    };

    creditEntry = await SalesAgentCommissionInstallment.create({
      ...base,
      salesAgentCommissionId: directContract.id,
      termId: directTerm.id,
      percentApplied: 40.0,
      amount: 40.0,
    });
    created.installmentIds.push(creditEntry.id);

    const overrideEntry = await SalesAgentCommissionInstallment.create({
      ...base,
      salesAgentCommissionId: overrideContract.id,
      termId: overrideTerm.id,
      percentApplied: 5.0,
      amount: 5.0,
    });
    created.installmentIds.push(overrideEntry.id);

    const sameId = await SalesAgentCommissionInstallment.findAll({ where: { paymentId } });
    expect(sameId).toHaveLength(2);

    // Mas duplicar contrato + payment + term + entryType continua bloqueado
    await expectUniqueViolation(
      SalesAgentCommissionInstallment.create({
        ...base,
        salesAgentCommissionId: directContract.id,
        termId: directTerm.id,
        percentApplied: 40.0,
        amount: 40.0,
      }),
    );
  });

  test('9. reversalOfId aponta para o crédito original (self-FK)', async () => {
    const reversal = await SalesAgentCommissionInstallment.create({
      salesAgentCommissionId: directContract.id,
      termId: directTerm.id,
      installmentNumber: 2,
      paymentId,
      referenceMonth: '2026-09',
      dueDate: '2026-09-10',
      amount: -40.0,
      status: 'pending',
      entryType: 'reversal',
      reversalOfId: creditEntry.id,
    });
    created.installmentIds.push(reversal.id);

    const loaded = await SalesAgentCommissionInstallment.findByPk(reversal.id, {
      include: [{ association: 'reversalOf' }, { association: 'term' }],
    });
    expect(loaded.reversalOf.id).toBe(creditEntry.id);
    expect(loaded.term.id).toBe(directTerm.id);

    const withReversals = await SalesAgentCommissionInstallment.findByPk(creditEntry.id, {
      include: [{ association: 'reversals' }],
    });
    expect(withReversals.reversals.map((r) => r.id)).toContain(reversal.id);

    // FK de verdade: id inexistente é rejeitado
    await expect(
      SalesAgentCommissionInstallment.create({
        salesAgentCommissionId: directContract.id,
        termId: directTerm.id,
        installmentNumber: 3,
        paymentId: 'pay_TESTE_B34_0002',
        referenceMonth: '2026-09',
        dueDate: '2026-09-10',
        amount: -1,
        entryType: 'reversal',
        reversalOfId: '00000000-0000-4000-8000-000000000000',
      }),
    ).rejects.toThrow();
  });

  test('a unique global de paymentId foi removida', async () => {
    const [idx] = await sequelize.query(`
      SELECT INDEX_NAME AS name, GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS cols, NON_UNIQUE
        FROM information_schema.STATISTICS
       WHERE TABLE_SCHEMA = DATABASE()
         AND TABLE_NAME = 'sales_agent_commission_installments'
       GROUP BY INDEX_NAME, NON_UNIQUE
    `);

    const uniques = idx.filter((i) => Number(i.NON_UNIQUE) === 0).map((i) => i.cols);
    expect(uniques).not.toContain('paymentId');
    expect(uniques).toContain('salesAgentCommissionId,paymentId,termId,entryType');
  });
});

describe('B3.4 — domínio de comissão de funcionário', () => {
  test('11. commission_entries permanece intocada', async () => {
    const cols = Object.keys(await describeTable('commission_entries')).sort();
    expect(cols).toEqual([
      'commissionAmount',
      'commissionPercent',
      'createdAt',
      'employeeId',
      'id',
      'notes',
      'paidAt',
      'referenceMonth',
      'salesAgentId',
      'signatureId',
      'status',
      'subscriptionFee',
      'tenantId',
      'updatedAt',
    ]);
  });
});
