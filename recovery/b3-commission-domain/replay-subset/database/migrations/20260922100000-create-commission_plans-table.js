'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.createTable(
        'commission_plans',
        {
          id: {
            type: Sequelize.UUID,
            defaultValue: Sequelize.UUIDV4,
            primaryKey: true,
            allowNull: false,
          },

          name: {
            type: Sequelize.STRING,
            allowNull: false,
            comment: 'Nome do template de comissão. Ex: "Padrão 12 meses escalonado"',
          },

          description: {
            type: Sequelize.STRING,
            allowNull: true,
          },

          // Sobre o que a "unidade" é contada:
          //  billing_month → cada mês de vigência da assinatura
          //  payment       → cada pagamento efetivamente recebido
          basis: {
            type: Sequelize.ENUM('billing_month', 'payment'),
            allowNull: false,
            defaultValue: 'billing_month',
          },

          // Como as faixas são percorridas:
          //  sequence → pela ordem das unidades (1ª, 2ª, 3ª...)
          //  volume   → RESERVADO, não implementado neste ciclo
          tierBasis: {
            type: Sequelize.ENUM('sequence', 'volume'),
            allowNull: false,
            defaultValue: 'sequence',
          },

          // NULL = ilimitado
          totalUnits: {
            type: Sequelize.INTEGER,
            allowNull: true,
          },

          isActive: {
            type: Sequelize.BOOLEAN,
            allowNull: false,
            defaultValue: true,
          },

          createdByUserId: {
            type: Sequelize.INTEGER,
            allowNull: true,
            references: { model: 'users', key: 'id' },
            onUpdate: 'CASCADE',
            onDelete: 'SET NULL',
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

      await queryInterface.addIndex('commission_plans', ['isActive'], { transaction });
      await queryInterface.addIndex('commission_plans', ['createdByUserId'], { transaction });

      await transaction.commit();
    } catch (err) {
      await transaction.rollback();
      throw err;
    }
  },

  async down(queryInterface) {
    await queryInterface.dropTable('commission_plans');
  },
};
