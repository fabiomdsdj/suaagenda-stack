'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('sales_agent_commission_installments', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
        allowNull: false,
      },

      installmentNumber: {
        type: Sequelize.INTEGER,
        allowNull: false,
        comment: 'Número da parcela: 1, 2, 3 ... commissionMonths',
      },

      paymentId: {
        type: Sequelize.STRING,
        allowNull: false,
        unique: true,
        comment: 'paymentId do Asaas',
      },

      amount: {
        type: Sequelize.DECIMAL(10, 2),
        allowNull: false,
        comment: 'Valor em R$ a pagar ao agente nessa parcela',
      },

      dueDate: {
        type: Sequelize.DATEONLY,
        allowNull: false,
        comment: 'Data prevista de pagamento ao agente',
      },

      paidAt: {
        type: Sequelize.DATE,
        allowNull: true,
        comment: 'Data em que foi efetivamente pago',
      },

      status: {
        type: Sequelize.ENUM('pending', 'paid', 'cancelled'),
        defaultValue: 'pending',
        allowNull: false,
      },

      salesAgentCommissionId: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'sales_agent_commissions', key: 'id' },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE', // se deletar a comissão, deleta as parcelas
      },

      referenceMonth: {
        type: Sequelize.STRING, // "2026-02"
        allowNull: false
      },
      
      approvedAt: {
        type: Sequelize.DATE,
        allowNull: true
      },
      
      paidAt: {
        type: Sequelize.DATE,
        allowNull: true
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

    await queryInterface.addIndex('sales_agent_commission_installments', ['salesAgentCommissionId']);
    await queryInterface.addIndex('sales_agent_commission_installments', ['dueDate']);
    await queryInterface.addIndex('sales_agent_commission_installments', ['status']);
    await queryInterface.addConstraint('sales_agent_commission_installments', {
      fields: ['paymentId'],
      type: 'unique',
      name: 'unique_payment_commission'
    });
    
  },

  async down(queryInterface) {
    await queryInterface.dropTable('sales_agent_commission_installments');
  },
};
