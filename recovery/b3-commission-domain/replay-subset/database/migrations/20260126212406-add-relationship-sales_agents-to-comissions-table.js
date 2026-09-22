'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn(
      'comissions',
      'salesAgentId',
      {
        type: Sequelize.UUID,
        allowNull: true,
      }
    );

    await queryInterface.addConstraint(
      'comissions',
      {
        fields: ['salesAgentId'],
        type: 'foreign key',
        name: 'fk_comission_sales_agent',
        references: {
          table: 'sales_agents',
          field: 'id',
        },
        onDelete: 'SET NULL',
      }
    );
  },

  async down(queryInterface) {
    await queryInterface.removeConstraint(
      'comissions',
      'fk_comission_sales_agent'
    );

    await queryInterface.removeColumn(
      'comissions',
      'salesAgentId'
    );
  },
};
