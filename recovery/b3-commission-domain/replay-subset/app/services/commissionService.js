const { Signature, CommissionEntry, Plan } = require('../models');

async function generateMonthlyCommissions(referenceMonth) {
  const signatures = await Signature.findAll({
    where: {
      isActive: 1,
    },
    include: [{ model: Plan }],
  });

  for (const sig of signatures) {
    const subscriptionFee = sig.Plan.price;
    const commissionPercent = 50;
    const commissionAmount = (subscriptionFee * commissionPercent) / 100;

    await CommissionEntry.findOrCreate({
      where: {
        tenantId: sig.tenantId,
        referenceMonth,
      },
      defaults: {
        salesAgentId: sig.salesAgentId,
        signatureId: sig.id,
        subscriptionFee,
        commissionPercent,
        commissionAmount,
        status: 'open',
      },
    });
  }
}

module.exports = {
  generateMonthlyCommissions,
};
