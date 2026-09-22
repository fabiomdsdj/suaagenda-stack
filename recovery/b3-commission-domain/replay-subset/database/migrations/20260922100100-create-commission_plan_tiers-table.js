'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.createTable(
        'commission_plan_tiers',
        {
          id: {
            type: Sequelize.UUID,
            defaultValue: Sequelize.UUIDV4,
            primaryKey: true,
            allowNull: false,
          },

          commissionPlanId: {
            type: Sequelize.UUID,
            allowNull: false,
            references: { model: 'commission_plans', key: 'id' },
            onUpdate: 'CASCADE',
            onDelete: 'CASCADE',
          },

          tierOrder: {
            type: Sequelize.INTEGER,
            allowNull: false,
            comment: 'Ordem da faixa dentro do plano: 1, 2, 3 ...',
          },

          fromUnit: {
            type: Sequelize.INTEGER,
            allowNull: false,
            comment: 'Primeira unidade coberta por essa faixa (1-based)',
          },

          toUnit: {
            type: Sequelize.INTEGER,
            allowNull: true,
            comment: 'Última unidade coberta. NULL = faixa aberta até o fim',
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

      await queryInterface.addIndex('commission_plan_tiers', ['commissionPlanId'], { transaction });

      await queryInterface.addConstraint('commission_plan_tiers', {
        fields: ['commissionPlanId', 'tierOrder'],
        type: 'unique',
        name: 'unique_commission_plan_tier_order',
        transaction,
      });

      await transaction.commit();
    } catch (err) {
      await transaction.rollback();
      throw err;
    }
  },

  async down(queryInterface) {
    await queryInterface.dropTable('commission_plan_tiers');
  },
};
