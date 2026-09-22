'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('sales_agent_commissions', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
        allowNull: false,
      },

      percent: {
        type: Sequelize.DECIMAL(5, 2),
        allowNull: false,
        comment: 'Percentual de comissão negociado com o agente para esse tenant',
      },

      startDate: {
        type: Sequelize.DATEONLY,
        allowNull: false,
        comment: 'Data de início da vigência (= data da assinatura)',
      },

      endDate: {
        type: Sequelize.DATEONLY,
        allowNull: false,
        comment: 'Data fim da vigência = startDate + commissionMonths',
      },

      commissionMonths: {
        type: Sequelize.INTEGER,
        allowNull: false,
        comment: 'Snapshot dos meses configurados no agente no momento da criação',
      },

      paidInstallments: {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 0,
        comment: 'Contador de parcelas já pagas',
      },

      totalInstallments: {
        type: Sequelize.INTEGER,
        allowNull: false,
        comment: 'Total de parcelas a pagar (mensal=12, trimestral=4, anual=1)',
      },

      status: {
        type: Sequelize.ENUM('pending', 'active', 'completed', 'cancelled'),
        defaultValue: 'active',
        allowNull: false,
      },

      // FKs
      salesAgentId: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'sales_agents', key: 'id' },
        onUpdate: 'CASCADE',
        onDelete: 'RESTRICT',
      },

      tenantId: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: { model: 'tenants', key: 'id' },
        onUpdate: 'CASCADE',
        onDelete: 'RESTRICT',
      },

      signatureId: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: { model: 'signatures', key: 'id' },
        onUpdate: 'CASCADE',
        onDelete: 'RESTRICT',
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

    // Índices úteis para consultas frequentes
    await queryInterface.addIndex('sales_agent_commissions', ['salesAgentId']);
    await queryInterface.addIndex('sales_agent_commissions', ['tenantId']);
    await queryInterface.addIndex('sales_agent_commissions', ['signatureId']);
    await queryInterface.addIndex('sales_agent_commissions', ['status']);
    await queryInterface.addIndex('sales_agent_commissions', ['endDate']); // filtrar comissões vencendo
  },

  async down(queryInterface) {
    await queryInterface.dropTable('sales_agent_commissions');
  },
};

