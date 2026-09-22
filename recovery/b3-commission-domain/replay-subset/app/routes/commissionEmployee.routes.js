'use strict';

/**
 * Routes: /api/commissions
 *
 * Registre no seu app.js / server.js:
 *   const commissionRoutes = require('./routes/commission.routes');
 *   app.use('/api/commissions', authMiddleware, commissionRoutes);
 */

const express    = require('express');
const router     = express.Router();
const controller = require('../controllers/commissionEmployee.controller');
const passport = require('passport');
const cfg = require('../../config/config');
const auth = passport.authenticate('jwt', cfg.jwtSession);

// 🔐 Protegido
router.use(auth);

router.get('/available', controller.listAvailable);

// ── Configuração de comissão do funcionário ──────────────────────────────────
// Bate com a aba "Comissão" do front (employee [id].vue e novo.vue)

// GET  /api/commissions/config/:employeeId
// → Carrega comissionTypeId, percent, comissionStatusId para popular o form
router.get('/config/:employeeId', controller.getConfig);

// PUT  /api/commissions/config/:employeeId
// → Salva/atualiza a config quando o user clica em "Salvar Alterações"
// Body: { comissionTypeId, percent, comissionStatusId }
router.put('/config/:employeeId', controller.upsertConfig);

// ── Entradas (histórico de comissões geradas) ────────────────────────────────

// GET  /api/commissions/entries/:employeeId
// Query: ?month=2026-03  ?status=pending|paid|cancelled
// → Lista as CommissionEntries do funcionário (para tabela de histórico no front)
router.get('/entries/:employeeId', controller.listEntries);

// GET  /api/commissions/entries/:employeeId/summary
// Query: ?month=2026-03  (opcional — sem month retorna tudo)
// → { totalGenerated, totalPending, totalPaid, totalCancelled, count }
router.get('/entries/:employeeId/summary', controller.summary);

// POST /api/commissions/entries/generate
// → Gera uma CommissionEntry a partir de uma venda/assinatura
// Body: { employeeId, subscriptionFee, signatureId?, referenceMonth?, notes? }
// Pode ser chamado internamente após criar uma Signature ou manualmente
router.post('/entries/generate', controller.generateEntry);

// PATCH /api/commissions/entries/:entryId/pay
// → Marca como paga + seta paidAt
router.patch('/entries/:entryId/pay', controller.markAsPaid);

// PATCH /api/commissions/entries/:entryId/cancel
// Body: { notes? }
router.patch('/entries/:entryId/cancel', controller.markAsCancelled);

// DELETE /api/commissions/entries/:entryId
// → Só deleta se status === 'pending'
router.delete('/entries/:entryId', controller.deleteEntry);

// ── Relatório por mês (visão do tenant/admin) ────────────────────────────────

// GET  /api/commissions/report?month=2026-03
// → Agrupado por funcionário: { employees: [...], totals: {...} }
router.get('/report', controller.reportByMonth);

module.exports = router;