'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('commission_entries', {
      id: {
        type: Sequelize.INTEGER,
        autoIncrement: true,
        primaryKey: true,
      },

      tenantId: {
        type: Sequelize.INTEGER,
        allowNull: false,
      },

      salesAgentId: {
        type: Sequelize.INTEGER,
        allowNull: false,
      },

      signatureId: {
        type: Sequelize.INTEGER,
        allowNull: false,
      },

      referenceMonth: {
        type: Sequelize.STRING(7), // YYYY-MM
        allowNull: false,
      },

      subscriptionFee: {
        type: Sequelize.DECIMAL(10, 2),
        allowNull: false,
      },

      commissionPercent: {
        type: Sequelize.INTEGER,
        allowNull: false,
      },

      commissionAmount: {
        type: Sequelize.DECIMAL(10, 2),
        allowNull: false,
      },

      status: {
        type: Sequelize.ENUM('open', 'paid', 'canceled'),
        defaultValue: 'open',
      },

      createdAt: {
        type: Sequelize.DATE,
        allowNull: false,
      },

      updatedAt: {
        type: Sequelize.DATE,
        allowNull: false,
      },
    });

    // 🔒 evita comissão duplicada no mês
    await queryInterface.addIndex(
      'commission_entries',
      ['tenantId', 'referenceMonth'],
      { unique: true, name: 'ux_commission_month' }
    );

    await queryInterface.addIndex(
      'commission_entries',
      ['salesAgentId', 'referenceMonth'],
      { name: 'idx_commission_sales_agent' }
    );
  },

  async down(queryInterface) {
    await queryInterface.dropTable('commission_entries');
  },
};
