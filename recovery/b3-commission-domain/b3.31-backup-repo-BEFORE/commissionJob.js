const axios = require('axios');
const { Op } = require('sequelize');
const { format, subMonths } = require('date-fns');

const {
  sequelize,
  SalesAgent,
  SalesAgentComission,
  SalesAgentComissionInstallment
} = require('../models');

const asaasApi = axios.create({
  baseURL: process.env.ASAAS_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
    access_token: process.env.ASAAS_API_KEY
  }
});

// ================================
// 1️⃣ APROVAR COMISSÕES (+7 dias)
// ================================
async function approveCommissions() {

  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

  await SalesAgentComissionInstallment.update(
    {
      status: 'approved',
      approvedAt: new Date()
    },
    {
      where: {
        status: 'pending',
        dueDate: { [Op.lte]: sevenDaysAgo }
      }
    }
  );

  console.log("✅ Comissões antigas aprovadas");
}

// ================================
// 2️⃣ FECHAMENTO MENSAL
// ================================
async function processMonthlyPayout() {

  const lastMonth = format(subMonths(new Date(), 1), 'yyyy-MM');

  const installments = await SalesAgentComissionInstallment.findAll({
    where: {
      status: 'approved',
      referenceMonth: lastMonth
    },
    include: [{
      model: SalesAgentComission,
      include: [SalesAgent]
    }]
  });

  if (!installments.length) {
    console.log("ℹ️ Nenhuma comissão para pagar no mês:", lastMonth);
    return;
  }

  // 🔥 Agrupar por vendedor
  const grouped = {};

  for (const inst of installments) {

    const agent = inst.SalesAgentComission.SalesAgent;

    if (!grouped[agent.id]) {
      grouped[agent.id] = {
        agent,
        installments: [],
        total: 0
      };
    }

    grouped[agent.id].installments.push(inst);
    grouped[agent.id].total += parseFloat(inst.amount);
  }

  // 🔥 Para cada vendedor gerar transferência
  for (const agentId in grouped) {

    const { agent, installments, total } = grouped[agentId];

    if (!agent.pixKey) {
      console.log("⚠️ Vendedor sem PIX cadastrado:", agent.id);
      continue;
    }

    try {

      await sequelize.transaction(async (t) => {

        // 💸 Transferência via Asaas
        await asaasApi.post('/transfers', {
          value: total,
          operationType: "PIX",
          pixAddressKey: agent.pixKey,
          description: `Comissão ${lastMonth}`
        });

        // 🔄 Marcar parcelas como pagas
        for (const inst of installments) {
          await inst.update({
            status: 'paid',
            paidAt: new Date()
          }, { transaction: t });
        }

      });

      console.log(`💰 Pago R$ ${total} para vendedor ${agent.name}`);

    } catch (error) {
      console.error("❌ Erro ao pagar vendedor:", agent.id, error.response?.data || error.message);
    }
  }
}

// ================================
// 3️⃣ JOB MASTER
// ================================
async function runCommissionJob() {

  console.log("🚀 Iniciando Commission Job...");

  await approveCommissions();
  await processMonthlyPayout();

  console.log("🏁 Commission Job finalizado");
}

module.exports = { runCommissionJob };
