const {
  SalesAgent,
  SalesAgentComission,
  SalesAgentComissionInstallment,
  Signature,
  Tenant
} = require('../models');

const { addMonths, isAfter, format} = require('date-fns');


async function processCommissionFromPayment(
  subscriptionId,
  paymentValue,
  paymentDate,
  paymentId,
  transaction
) {
  try {

    if (!subscriptionId || !paymentId) return;

    // 🛑 1️⃣ PROTEÇÃO MÁXIMA — já processou esse pagamento?
    const alreadyProcessed = await SalesAgentComissionInstallment.findOne({
      where: { paymentId }
    });

    if (alreadyProcessed) {
      console.log("⚠️ Comissão já processada para esse paymentId:", paymentId);
      return;
    }

    // 🔎 Busca assinatura
    const signature = await Signature.findOne({
      where: { asaasId: subscriptionId }
    });

    if (!signature) return;

    // 🔎 Busca tenant
    const tenant = await Tenant.findByPk(signature.tenantId);
    if (!tenant?.salesAgentId) return;

    // 🔎 Busca vendedor
    const agent = await SalesAgent.findByPk(tenant.salesAgentId);
    if (!agent?.commissionPercent) return;

    // 🔎 Busca comissão ativa
    let commission = await SalesAgentComission.findOne({
      where: {
        tenantId: tenant.id,
        signatureId: signature.id,
        status: 'active'
      }
    });

    // 🧠 Se não existir, cria contrato lógico
    if (!commission) {

      const startDate = new Date(signature.start);
      const endDate = addMonths(startDate, agent.commissionMonths);

      commission = await SalesAgentComission.create({
        percent: agent.commissionPercent,
        startDate,
        endDate,
        commissionMonths: agent.commissionMonths,
        paidInstallments: 0,
        totalInstallments: agent.commissionMonths,
        status: 'active',
        salesAgentId: agent.id,
        tenantId: tenant.id,
        signatureId: signature.id
      }, { transaction });
    }

    // 🚫 Fora do período de comissão
    if (isAfter(new Date(paymentDate), new Date(commission.endDate))) {
      return;
    }

    // 💰 Calcula comissão baseada no valor REAL pago
    const commissionAmount =
      (parseFloat(paymentValue) * parseFloat(commission.percent)) / 100;

    const nextInstallmentNumber = commission.paidInstallments + 1;

    const referenceMonth = format(new Date(paymentDate), 'yyyy-MM');

    // 💾 Cria parcela já com paymentId único
    await SalesAgentComissionInstallment.create({
      installmentNumber: nextInstallmentNumber,
      amount: commissionAmount.toFixed(2),
      dueDate: paymentDate,
      status: 'pending',
      paymentId, // 🔥 IDEMPOTÊNCIA REAL
      referenceMonth,
      salesAgentComissionId: commission.id
    }, { transaction });

    const newPaid = nextInstallmentNumber;

    await commission.update({
      paidInstallments: newPaid,
      status:
        newPaid >= commission.commissionMonths
          ? 'completed'
          : 'active'
    }, { transaction });

    console.log("✅ Comissão criada com sucesso:", paymentId);

  } catch (error) {

    // Se for erro de unique constraint → ignora (já processado)
    if (error.name === 'SequelizeUniqueConstraintError') {
      console.log("⚠️ Tentativa duplicada bloqueada pelo banco:", paymentId);
      return;
    }

    console.error("❌ Erro ao processar comissão:", error);
  }
}

module.exports = { processCommissionFromPayment };
