'use strict';

//controllers/commissionEmployee.controller.js

/** ──────────────────────────────────────────────────────────────────────────
 * Controller: commission.controller.js
 *
 * Endpoints cobertos:
 *
 *  Configuração (tabela `comissions` — a "config" do employee)
 *  ─────────────────────────────────────────────────────────
 *  GET    /api/commissions/config/:employeeId          → getConfig
 *  PUT    /api/commissions/config/:employeeId          → upsertConfig
 *
 *  Entradas (tabela `commission_entries` — o histórico)
 *  ────────────────────────────────────────────────────
 *  GET    /api/commissions/entries/:employeeId         → listEntries
 *  GET    /api/commissions/entries/:employeeId/summary → summary
 *  POST   /api/commissions/entries/generate            → generateEntry  (interno/webhook)
 *  PATCH  /api/commissions/entries/:entryId/pay        → markAsPaid
 *  PATCH  /api/commissions/entries/:entryId/cancel     → markAsCancelled
 *  DELETE /api/commissions/entries/:entryId            → deleteEntry
 *
 *  Relatório tenant
 *  ─────────────────
 *  GET    /api/commissions/report                      → reportByMonth
 * ─────────────────────────────────────────────────────────────────────────*/

const { Op } = require('sequelize');
const db = require('../models'); // ajuste o caminho conforme seu projeto

const {
  Comission,
  CommissionEntry,
  Employee,
  ComissionType,
  ComissionStatus,
} = db;

// ─── helpers ────────────────────────────────────────────────────────────────

/**
 * Calcula o valor da comissão.
 * @param {number} fee      - valor base (subscriptionFee)
 * @param {number} percent  - percentual (ex: 10.5)
 * @returns {number}        - valor arredondado em 2 casas
 */
function calcAmount(fee, percent) {
  return Math.round(((fee * percent) / 100) * 100) / 100;
}

/**
 * Retorna "YYYY-MM" do mês atual.
 */
function currentMonth() {
  return new Date().toISOString().slice(0, 7);
}

/**
 * Inclui o Employee com a config de Comission.
 */
const employeeWithComission = {
  model: Employee,
  as: 'employee',
  attributes: ['id', 'firstName', 'lastName', 'email'],
  include: [
    {
      model: Comission,
      as: 'comission',
      include: [
        { model: ComissionType,   as: 'comissionType' },
        { model: ComissionStatus, as: 'comissionStatus' },
      ],
    },
  ],
};

// ─── CONFIG ─────────────────────────────────────────────────────────────────

/**
 * GET /api/commissions/config/:employeeId
 * Retorna a configuração de comissão do funcionário.
 */
async function getConfig(req, res) {
  try {
    const { employeeId } = req.params;
    const { tenantId }   = req.user; // assumindo JWT middleware

    const employee = await Employee.findOne({
      where: { id: employeeId, tenantId },
      include: [
        {
          model: Comission,
          as: 'comission',
          include: [
            { model: ComissionType,   as: 'comissionType' },
            { model: ComissionStatus, as: 'comissionStatus' },
          ],
        },
      ],
    });

    if (!employee) {
      return res.status(404).json({ message: 'Funcionário não encontrado' });
    }

    return res.json(employee.comission ?? null);
  } catch (err) {
    console.error('[commission.getConfig]', err);
    return res.status(500).json({ message: 'Erro interno' });
  }
}

/**
 * PUT /api/commissions/config/:employeeId
 *
 * Body esperado (bate com o front):
 * {
 *   comissionTypeId:   number,
 *   percent:           number,   (0–100)
 *   comissionStatusId: number,
 * }
 *
 * Faz upsert: se o employee já tem comissionId, atualiza; senão cria e vincula.
 */
async function upsertConfig(req, res) {
  try {
    const { employeeId } = req.params;
    const { tenantId }   = req.user;
    const { comissionTypeId, percent, comissionStatusId } = req.body;

    // Validações
    if (percent === undefined || percent === null) {
      return res.status(400).json({ message: '`percent` é obrigatório' });
    }
    if (Number(percent) < 0 || Number(percent) > 100) {
      return res.status(400).json({ message: '`percent` deve estar entre 0 e 100' });
    }

    const employee = await Employee.findOne({ where: { id: employeeId, tenantId } });
    if (!employee) {
      return res.status(404).json({ message: 'Funcionário não encontrado' });
    }

    let comission;

    if (employee.comissionId) {
      // Atualiza existente
      comission = await Comission.findByPk(employee.comissionId);
      await comission.update({ percent, comissionTypeId, comissionStatusId });
    } else {
      // Cria novo e vincula ao employee
      comission = await Comission.create({
        tenantId,
        percent,
        comissionTypeId,
        comissionStatusId,
      });
      await employee.update({ comissionId: comission.id });
    }

    // Retorna config completa com includes
    const full = await Comission.findByPk(comission.id, {
      include: [
        { model: ComissionType,   as: 'comissionType' },
        { model: ComissionStatus, as: 'comissionStatus' },
      ],
    });

    return res.json(full);
  } catch (err) {
    console.error('[commission.upsertConfig]', err);
    return res.status(500).json({ message: 'Erro interno' });
  }
}

// ─── ENTRIES ────────────────────────────────────────────────────────────────

/**
 * GET /api/commissions/entries/:employeeId
 * Query params opcionais: ?month=2026-03&status=pending
 */
async function listEntries(req, res) {
  try {
    const { employeeId } = req.params;
    const { tenantId }   = req.user;
    const { month, status } = req.query;

    const where = { employeeId, tenantId };
    if (month)  where.referenceMonth = month;
    if (status) where.status         = status;

    const entries = await CommissionEntry.findAll({
      where,
      order: [['referenceMonth', 'DESC'], ['createdAt', 'DESC']],
      include: [employeeWithComission],
    });

    return res.json(entries);
  } catch (err) {
    console.error('[commission.listEntries]', err);
    return res.status(500).json({ message: 'Erro interno' });
  }
}

/**
 * GET /api/commissions/entries/:employeeId/summary
 * Retorna totais agrupados por status.
 */
async function summary(req, res) {
  try {
    const { employeeId } = req.params;
    const { tenantId }   = req.user;
    const { month }      = req.query; // opcional

    const where = { employeeId, tenantId };
    if (month) where.referenceMonth = month;

    const entries = await CommissionEntry.findAll({ where });

    const reduce = (status) =>
      entries
        .filter((e) => e.status === status)
        .reduce((acc, e) => acc + Number(e.commissionAmount), 0);

    const totalPending   = reduce('pending');
    const totalPaid      = reduce('paid');
    const totalCancelled = reduce('cancelled');
    const totalGenerated = totalPending + totalPaid; // cancelados fora do total

    return res.json({
      totalGenerated: +totalGenerated.toFixed(2),
      totalPending:   +totalPending.toFixed(2),
      totalPaid:      +totalPaid.toFixed(2),
      totalCancelled: +totalCancelled.toFixed(2),
      count: {
        pending:   entries.filter((e) => e.status === 'pending').length,
        paid:      entries.filter((e) => e.status === 'paid').length,
        cancelled: entries.filter((e) => e.status === 'cancelled').length,
      },
    });
  } catch (err) {
    console.error('[commission.summary]', err);
    return res.status(500).json({ message: 'Erro interno' });
  }
}

/**
 * POST /api/commissions/entries/generate
 *
 * Chamado internamente (ex: após criar uma assinatura/venda).
 * Também pode ser chamado manualmente via painel admin.
 *
 * Body:
 * {
 *   employeeId:      number,
 *   subscriptionFee: number,   (valor base — ex: valor da mensalidade)
 *   signatureId:     number,   (opcional)
 *   referenceMonth:  string,   (opcional — padrão: mês atual "YYYY-MM")
 *   notes:           string,   (opcional)
 * }
 */
async function generateEntry(req, res) {
  try {
    const { tenantId } = req.user;
    const {
      employeeId,
      subscriptionFee,
      signatureId,
      referenceMonth = currentMonth(),
      notes,
    } = req.body;

    if (!employeeId || subscriptionFee === undefined) {
      return res.status(400).json({ message: '`employeeId` e `subscriptionFee` são obrigatórios' });
    }

    // Busca employee com config de comissão
    const employee = await Employee.findOne({
      where: { id: employeeId, tenantId },
      include: [
        {
          model: Comission,
          as: 'comission',
          include: [{ model: ComissionStatus, as: 'comissionStatus' }],
        },
      ],
    });

    if (!employee) {
      return res.status(404).json({ message: 'Funcionário não encontrado' });
    }

    const config = employee.comission;

    // Sem config ou comissão inativa → não gera
    if (!config) {
      return res.status(422).json({ message: 'Funcionário não possui configuração de comissão' });
    }
    if (config.comissionStatus?.name !== 'active') {
      return res.status(422).json({ message: 'Comissão do funcionário está inativa' });
    }

    const commissionPercent = Number(config.percent);
    const commissionAmount  = calcAmount(Number(subscriptionFee), commissionPercent);

    const entry = await CommissionEntry.create({
      tenantId,
      employeeId,
      signatureId:    signatureId ?? null,
      referenceMonth,
      subscriptionFee: Number(subscriptionFee),
      commissionPercent,
      commissionAmount,
      status: 'pending',
      notes:  notes ?? null,
    });

    return res.status(201).json(entry);
  } catch (err) {
    console.error('[commission.generateEntry]', err);
    return res.status(500).json({ message: 'Erro interno' });
  }
}

/**
 * PATCH /api/commissions/entries/:entryId/pay
 * Marca a entrada como paga.
 */
async function markAsPaid(req, res) {
  try {
    const { entryId }  = req.params;
    const { tenantId } = req.user;

    const entry = await CommissionEntry.findOne({ where: { id: entryId, tenantId } });
    if (!entry) {
      return res.status(404).json({ message: 'Entrada não encontrada' });
    }
    if (entry.status === 'paid') {
      return res.status(400).json({ message: 'Entrada já foi paga' });
    }
    if (entry.status === 'cancelled') {
      return res.status(400).json({ message: 'Entrada cancelada não pode ser paga' });
    }

    await entry.update({ status: 'paid', paidAt: new Date() });
    return res.json(entry);
  } catch (err) {
    console.error('[commission.markAsPaid]', err);
    return res.status(500).json({ message: 'Erro interno' });
  }
}

/**
 * PATCH /api/commissions/entries/:entryId/cancel
 */
async function markAsCancelled(req, res) {
  try {
    const { entryId }  = req.params;
    const { tenantId } = req.user;
    const { notes }    = req.body;

    const entry = await CommissionEntry.findOne({ where: { id: entryId, tenantId } });
    if (!entry) {
      return res.status(404).json({ message: 'Entrada não encontrada' });
    }
    if (entry.status === 'paid') {
      return res.status(400).json({ message: 'Entrada já paga não pode ser cancelada' });
    }

    await entry.update({
      status: 'cancelled',
      notes:  notes ? `[CANCELADO] ${notes}` : entry.notes,
    });
    return res.json(entry);
  } catch (err) {
    console.error('[commission.markAsCancelled]', err);
    return res.status(500).json({ message: 'Erro interno' });
  }
}

/**
 * DELETE /api/commissions/entries/:entryId
 * Só permite deletar entradas pendentes.
 */
async function deleteEntry(req, res) {
  try {
    const { entryId }  = req.params;
    const { tenantId } = req.user;

    const entry = await CommissionEntry.findOne({ where: { id: entryId, tenantId } });
    if (!entry) {
      return res.status(404).json({ message: 'Entrada não encontrada' });
    }
    if (entry.status !== 'pending') {
      return res.status(400).json({
        message: 'Apenas entradas pendentes podem ser removidas',
      });
    }

    await entry.destroy();
    return res.json({ success: true });
  } catch (err) {
    console.error('[commission.deleteEntry]', err);
    return res.status(500).json({ message: 'Erro interno' });
  }
}

// ─── RELATÓRIO ───────────────────────────────────────────────────────────────

/**
 * GET /api/commissions/report
 * Query: ?month=2026-03  (obrigatório)
 *
 * Retorna um resumo por funcionário do tenant para o mês informado.
 */
async function reportByMonth(req, res) {
  try {
    const { tenantId } = req.user;
    const { month }    = req.query;

    if (!month || !/^\d{4}-\d{2}$/.test(month)) {
      return res.status(400).json({ message: '`month` obrigatório no formato YYYY-MM' });
    }

    const entries = await CommissionEntry.findAll({
      where: { tenantId, referenceMonth: month },
      include: [
        {
          model: Employee,
          as: 'employee',
          attributes: ['id', 'firstName', 'lastName'],
        },
      ],
      order: [['commissionAmount', 'DESC']],
    });

    // Agrupa por employee
    const byEmployee = {};
    for (const e of entries) {
      const key = e.employeeId;
      if (!byEmployee[key]) {
        byEmployee[key] = {
          employeeId:   e.employeeId,
          employeeName: `${e.employee?.firstName ?? ''} ${e.employee?.lastName ?? ''}`.trim(),
          pending:   0,
          paid:      0,
          cancelled: 0,
          total:     0,
          entries:   [],
        };
      }
      const grp = byEmployee[key];
      const amt = Number(e.commissionAmount);
      grp[e.status] += amt;
      if (e.status !== 'cancelled') grp.total += amt;
      grp.entries.push(e);
    }

    const report = {
      month,
      employees: Object.values(byEmployee).map((g) => ({
        ...g,
        pending:   +g.pending.toFixed(2),
        paid:      +g.paid.toFixed(2),
        cancelled: +g.cancelled.toFixed(2),
        total:     +g.total.toFixed(2),
      })),
      totals: {
        pending:   +Object.values(byEmployee).reduce((a, g) => a + g.pending, 0).toFixed(2),
        paid:      +Object.values(byEmployee).reduce((a, g) => a + g.paid, 0).toFixed(2),
        cancelled: +Object.values(byEmployee).reduce((a, g) => a + g.cancelled, 0).toFixed(2),
        total:     +Object.values(byEmployee).reduce((a, g) => a + g.total, 0).toFixed(2),
      },
    };

    return res.json(report);
  } catch (err) {
    console.error('[commission.reportByMonth]', err);
    return res.status(500).json({ message: 'Erro interno' });
  }
}

async function listAvailable(req, res) {
  try {
    const comissions = await Comission.findAll({
      include: [
        { model: ComissionType,   as: 'comissionType',   attributes: ['id', 'name', 'label'] },
        { model: ComissionStatus, as: 'comissionStatus', attributes: ['id', 'name', 'label'] },
      ],
      order: [['percent', 'ASC']],
    });

    return res.json(comissions);
  } catch (err) {
    console.error('[commission.listAvailable]', err);
    return res.status(500).json({ message: 'Erro interno' });
  }
}

// ─── exports ─────────────────────────────────────────────────────────────────

module.exports = {
  getConfig,
  upsertConfig,
  listEntries,
  summary,
  generateEntry,
  markAsPaid,
  markAsCancelled,
  deleteEntry,
  reportByMonth,
  listAvailable
};