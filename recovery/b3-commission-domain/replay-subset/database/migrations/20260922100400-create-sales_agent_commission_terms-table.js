'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      // SNAPSHOT IMUTÁVEL das faixas contratadas.
      // Copiado de commission_plan_tiers no momento da criação do contrato.
      // Alterar o plano depois NÃO altera contratos já fechados.
      await queryInterface.createTable(
        'sales_agent_commission_terms',
        {
          id: {
            type: Sequelize.UUID,
            defaultValue: Sequelize.UUIDV4,
            primaryKey: true,
            allowNull: false,
          },

          salesAgentCommissionId: {
            type: Sequelize.UUID,
            allowNull: false,
            references: { model: 'sales_agent_commissions', key: 'id' },
            onUpdate: 'CASCADE',
            onDelete: 'CASCADE',
          },

          tierOrder: {
            type: Sequelize.INTEGER,
            allowNull: false,
          },

          fromUnit: {
            type: Sequelize.INTEGER,
            allowNull: false,
          },

          toUnit: {
            type: Sequelize.INTEGER,
            allowNull: true,
            comment: 'NULL = faixa aberta até o fim do contrato',
          },

          percent: {
            type: Sequelize.DECIMAL(5, 2),
            allowNull: false,
          },

          createdAt: {
            type: Sequelize.DATE,
            allowNull: false,
          },
          updatedAt: {
            type: Sequelize.DATE,
            allowNull: false,
          },
        },
        { transaction },
      );

      await queryInterface.addIndex('sales_agent_commission_terms', ['salesAgentCommissionId'], {
        transaction,
      });
      await queryInterface.addIndex(
        'sales_agent_commission_terms',
        ['salesAgentCommissionId', 'tierOrder'],
        { name: 'sales_agent_commission_terms_commission_tier_order', transaction },
      );

      await transaction.commit();
    } catch (err) {
      await transaction.rollback();
      throw err;
    }
  },

  async down(queryInterface) {
    await queryInterface.dropTable('sales_agent_commission_terms');
  },
};
