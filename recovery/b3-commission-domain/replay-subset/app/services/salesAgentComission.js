const { addMonths, format } = require('date-fns');
const { SalesAgent, SalesAgentComission, SalesAgentComissionInstallment, Signature, Plan } = require('../models');

/**
 * Gera a SalesAgentComission + installments quando um Tenant assina.
 *
 * Regras:
 *  - Mensal   → totalInstallments = commissionMonths,  1 parcela/mês
 *  - Trimestral → totalInstallments = commissionMonths / 3 (arredondado), 1 parcela/trim
 *  - Anual    → totalInstallments = 1, valor = percent * receita anual
 *
 * @param {number} tenantId
 * @param {number} signatureId
 * @param {number} planValueMonthly  — valor mensal do plano em R$ (base de cálculo)
 */
async function createComissionForSignature(tenantId, signatureId, planValueMonthly) {
  // 1. Busca a assinatura para pegar datas e ciclo
  const signature = await Signature.findByPk(signatureId, {
    include: [{ association: 'plan' }],
  });
  if (!signature) throw new Error('Signature não encontrada');

  // 2. Busca o SalesAgent do tenant
  const { Tenant } = require('../models');
  const tenant = await Tenant.findByPk(tenantId, {
    include: [{ association: 'salesAgent' }],
  });
  if (!tenant?.salesAgentId) return null; // tenant sem agente, ignora

  const agent = await SalesAgent.findByPk(tenant.salesAgentId);
  if (!agent) return null;

  const commissionMonths = agent.commissionMonths || 12;
  const percent          = parseFloat(agent.commissionPercent || 0);
  const startDate        = signature.start || new Date();
  const endDate          = addMonths(new Date(startDate), commissionMonths);

  // 3. Detecta o ciclo da assinatura pelo Plan (campo cycle: 'monthly'|'quarterly'|'yearly')
  const cycle = signature.plan?.cycle || 'monthly';

  let totalInstallments;
  let monthsPerInstallment;

  if (cycle === 'yearly') {
    totalInstallments     = 1;
    monthsPerInstallment  = commissionMonths; // paga tudo de uma vez
  } else if (cycle === 'quarterly') {
    totalInstallments     = Math.ceil(commissionMonths / 3);
    monthsPerInstallment  = 3;
  } else {
    // monthly (padrão)
    totalInstallments     = commissionMonths;
    monthsPerInstallment  = 1;
  }

  // 4. Cria a SalesAgentComission
  const comission = await SalesAgentComission.create({
    percent,
    startDate:         format(new Date(startDate), 'yyyy-MM-dd'),
    endDate:           format(endDate, 'yyyy-MM-dd'),
    commissionMonths,
    totalInstallments,
    paidInstallments:  0,
    status:            'active',
    salesAgentId:      agent.id,
    tenantId,
    signatureId,
  });

  // 5. Gera as parcelas
  const installments = [];
  for (let i = 0; i < totalInstallments; i++) {
    const dueDate = addMonths(new Date(startDate), i * monthsPerInstallment);

    // Valor da parcela: percent% sobre o valor mensal × meses cobertos pela parcela
    const amount = (planValueMonthly * monthsPerInstallment * percent) / 100;

    installments.push({
      installmentNumber: i + 1,
      amount:            parseFloat(amount.toFixed(2)),
      dueDate:           format(dueDate, 'yyyy-MM-dd'),
      status:            'pending',
      salesAgentComissionId: comission.id,
    });
  }

  await SalesAgentComissionInstallment.bulkCreate(installments);

  return comission;
}

/**
 * Marca uma parcela como paga e atualiza o contador na comissão.
 */
async function payInstallment(installmentId) {
  const installment = await SalesAgentComissionInstallment.findByPk(installmentId, {
    include: [{ association: 'comission' }],
  });
  if (!installment) throw new Error('Parcela não encontrada');
  if (installment.status === 'paid') throw new Error('Parcela já foi paga');

  await installment.update({ status: 'paid', paidAt: new Date() });

  const comission = installment.comission;
  const newPaid   = comission.paidInstallments + 1;
  const completed = newPaid >= comission.totalInstallments;

  await comission.update({
    paidInstallments: newPaid,
    status: completed ? 'completed' : 'active',
  });

  return installment;
}

module.exports = { createComissionForSignature, payInstallment };