'use strict';

/** ──────────────────────────────────────────────────────────────────────────
 * Migration: commission_entries
 *
 * O que faz:
 *  1. Adiciona coluna `employeeId` (FK → employees) se ainda não existir
 *  2. Garante que `commissionPercent` aceita DECIMAL (era INTEGER)
 *  3. Adiciona coluna `paidAt` para registrar data do pagamento
 *  4. Adiciona coluna `notes` para observações
 *  5. Cria índices úteis para queries de listagem/relatório
 *
 * Down reverte tudo na ordem inversa.
 * ─────────────────────────────────────────────────────────────────────────*/

module.exports = {
  async up(queryInterface, Sequelize) {
    const tableDesc = await queryInterface.describeTable('commission_entries');

    // ── 1. employeeId ──────────────────────────────────────────────────────
    if (!tableDesc.employeeId) {
      await queryInterface.addColumn('commission_entries', 'employeeId', {
        type: Sequelize.INTEGER,
        allowNull: true, // true para não quebrar linhas legadas de salesAgent
        references: { model: 'employees', key: 'id' },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL',
        after: 'salesAgentId',
      });
    }

    // ── 2. commissionPercent: INTEGER → DECIMAL(5,2) ───────────────────────
    //    Permite valores como 10.50%
    await queryInterface.changeColumn('commission_entries', 'commissionPercent', {
      type: Sequelize.DECIMAL(5, 2),
      allowNull: true,
    });

    // ── 3. paidAt ──────────────────────────────────────────────────────────
    if (!tableDesc.paidAt) {
      await queryInterface.addColumn('commission_entries', 'paidAt', {
        type: Sequelize.DATE,
        allowNull: true,
        after: 'status',
      });
    }

    // ── 4. notes ───────────────────────────────────────────────────────────
    if (!tableDesc.notes) {
      await queryInterface.addColumn('commission_entries', 'notes', {
        type: Sequelize.TEXT,
        allowNull: true,
        after: 'paidAt',
      });
    }

    // ── 5. Índices ─────────────────────────────────────────────────────────
    const indexes = await queryInterface.showIndex('commission_entries');
    const indexNames = indexes.map((i) => i.name);

    if (!indexNames.includes('idx_ce_employee_month')) {
      await queryInterface.addIndex('commission_entries', ['employeeId', 'referenceMonth'], {
        name: 'idx_ce_employee_month',
      });
    }

    if (!indexNames.includes('idx_ce_tenant_month')) {
      await queryInterface.addIndex('commission_entries', ['tenantId', 'referenceMonth'], {
        name: 'idx_ce_tenant_month',
      });
    }

    if (!indexNames.includes('idx_ce_status')) {
      await queryInterface.addIndex('commission_entries', ['status'], {
        name: 'idx_ce_status',
      });
    }
  },

  async down(queryInterface, Sequelize) {
    // Remove índices
    await queryInterface.removeIndex('commission_entries', 'idx_ce_employee_month').catch(() => {});
    await queryInterface.removeIndex('commission_entries', 'idx_ce_tenant_month').catch(() => {});
    await queryInterface.removeIndex('commission_entries', 'idx_ce_status').catch(() => {});

    // Remove colunas novas
    await queryInterface.removeColumn('commission_entries', 'notes').catch(() => {});
    await queryInterface.removeColumn('commission_entries', 'paidAt').catch(() => {});
    await queryInterface.removeColumn('commission_entries', 'employeeId').catch(() => {});

    // Reverte commissionPercent para INTEGER
    await queryInterface.changeColumn('commission_entries', 'commissionPercent', {
      type: Sequelize.INTEGER,
      allowNull: true,
    });
  },
};