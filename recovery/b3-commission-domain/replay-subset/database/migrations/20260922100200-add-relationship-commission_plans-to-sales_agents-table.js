'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      // Plano padrão sugerido ao contratar um novo tenant para esse agente.
      // É apenas um default: o contrato (sales_agent_commissions) guarda o
      // snapshot real das faixas em sales_agent_commission_terms.
      await queryInterface.addColumn(
        'sales_agents',
        'defaultCommissionPlanId',
        {
          type: Sequelize.DataTypes.UUID,
          allowNull: true,
          references: { model: 'commission_plans', key: 'id' },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        { transaction },
      );

      await transaction.commit();
    } catch (err) {
      await transaction.rollback();
      throw err;
    }
  },

  async down(queryInterface) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.removeColumn('sales_agents', 'defaultCommissionPlanId', { transaction });
      await transaction.commit();
    } catch (err) {
      await transaction.rollback();
      throw err;
    }
  },
};
