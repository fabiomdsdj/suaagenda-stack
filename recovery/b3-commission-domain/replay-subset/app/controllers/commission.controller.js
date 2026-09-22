const { CommissionEntry } = require('../models');

module.exports = {

  async listBySalesAgent(req, res) {
    const { salesAgentId } = req.params;

    const commissions = await CommissionEntry.findAll({
      where: { salesAgentId },
      order: [['referenceMonth', 'DESC']],
    });

    return res.json(commissions);
  },

  async markAsPaid(req, res) {
    const { id } = req.params;

    await CommissionEntry.update(
      { status: 'paid' },
      { where: { id } }
    );

    return res.json({ success: true });
  },

  
};
