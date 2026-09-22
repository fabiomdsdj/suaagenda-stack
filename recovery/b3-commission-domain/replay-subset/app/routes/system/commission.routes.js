const express = require('express');
const CommissionController = require('../../controllers/commission.controller');

const router = express.Router();

router.get(
  '/sales-agent/:salesAgentId',
  CommissionController.listBySalesAgent
);

router.post(
  '/:id/pay',
  CommissionController.markAsPaid
);

module.exports = router;
