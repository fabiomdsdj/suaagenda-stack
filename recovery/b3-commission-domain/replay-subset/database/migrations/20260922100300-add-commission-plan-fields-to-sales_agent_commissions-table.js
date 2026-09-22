'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    const { DataTypes } = Sequelize;
    const transaction = await queryInterface.sequelize.transaction();
    try {
      // ---------------------------------------------------------------
      // 1. Vínculo com o template de plano + snapshot das regras de topo
      // ---------------------------------------------------------------
      await queryInterface.addColumn(
        'sales_agent_commissions',
        'commissionPlanId',
        {
          type: DataTypes.UUID,
          allowNull: true,
          references: { model: 'commission_plans', key: 'id' },
          onUpdate: 'CASCADE',
          onDelete: 'RESTRICT',
        },
        { transaction },
      );

      await queryInterface.addColumn(
        'sales_agent_commissions',
        'basis',
        {
          type: DataTypes.ENUM('billing_month', 'payment'),
          allowNull: false,
          defaultValue: 'billing_month',
          comment: 'Snapshot do basis do plano no momento da contratação',
        },
        { transaction },
      );

      await queryInterface.addColumn(
        'sales_agent_commissions',
        'tierBasis',
        {
          type: DataTypes.ENUM('sequence', 'volume'),
          allowNull: false,
          defaultValue: 'sequence',
          comment: "Snapshot do tierBasis do plano. 'volume' reservado, não implementado",
        },
        { transaction },
      );

      await queryInterface.addColumn(
        'sales_agent_commissions',
        'totalUnits',
        {
          type: DataTypes.INTEGER,
          allowNull: true,
          comment: 'Snapshot do totalUnits do plano. NULL = ilimitado',
        },
        { transaction },
      );

      await queryInterface.addColumn(
        'sales_agent_commissions',
        'hardEndDate',
        {
          type: DataTypes.DATEONLY,
          allowNull: true,
          comment: 'Corte duro opcional: nada é gerado depois dessa data, mesmo com unidades restantes',
        },
        { transaction },
      );

      // ---------------------------------------------------------------
      // 2. direct x override
      // ---------------------------------------------------------------
      await queryInterface.addColumn(
        'sales_agent_commissions',
        'kind',
        {
          type: DataTypes.ENUM('direct', 'override'),
          allowNull: false,
          defaultValue: 'direct',
          comment: "direct = agente que vendeu; override = comissão do agente pai sobre a venda",
        },
        { transaction },
      );

      await queryInterface.addColumn(
        'sales_agent_commissions',
        'parentCommissionId',
        {
          type: DataTypes.UUID,
          allowNull: true,
          references: { model: 'sales_agent_commissions', key: 'id' },
          onUpdate: 'CASCADE',
          onDelete: 'RESTRICT',
          comment: 'Contrato direct que originou esse override. Lógica pai/filho NÃO implementada neste ciclo',
        },
        { transaction },
      );

      // ---------------------------------------------------------------
      // 3. Status: 'pending' sai (nunca foi gravado), 'suspended' entra
      // ---------------------------------------------------------------
      await queryInterface.changeColumn(
        'sales_agent_commissions',
        'status',
        {
          type: DataTypes.ENUM('active', 'suspended', 'completed', 'cancelled'),
          allowNull: false,
          defaultValue: 'active',
        },
        { transaction },
      );

      // ---------------------------------------------------------------
      // 4. Campos aposentados conceitualmente: passam a ser opcionais.
      //    Continuam na tabela para não quebrar o código atual, mas a nova
      //    regra (faixas em sales_agent_commission_terms) não depende deles.
      // ---------------------------------------------------------------
      await queryInterface.changeColumn(
        'sales_agent_commissions',
        'percent',
        {
          type: DataTypes.DECIMAL(5, 2),
          allowNull: true,
          comment: 'DEPRECADO: use sales_agent_commission_terms.percent',
        },
        { transaction },
      );

      await queryInterface.changeColumn(
        'sales_agent_commissions',
        'endDate',
        {
          type: DataTypes.DATEONLY,
          allowNull: true,
          comment: 'DEPRECADO: use totalUnits / hardEndDate',
        },
        { transaction },
      );

      await queryInterface.changeColumn(
        'sales_agent_commissions',
        'commissionMonths',
        {
          type: DataTypes.INTEGER,
          allowNull: true,
          comment: 'DEPRECADO: use totalUnits',
        },
        { transaction },
      );

      await queryInterface.changeColumn(
        'sales_agent_commissions',
        'totalInstallments',
        {
          type: DataTypes.INTEGER,
          allowNull: true,
          comment: 'DEPRECADO: derivado das parcelas geradas',
        },
        { transaction },
      );

      // ---------------------------------------------------------------
      // 5. Unicidade do contrato.
      //    Permite direct + override coexistirem para o mesmo
      //    agente/tenant/assinatura, mas nunca dois do mesmo kind.
      // ---------------------------------------------------------------
      await queryInterface.addConstraint('sales_agent_commissions', {
        fields: ['salesAgentId', 'tenantId', 'signatureId', 'kind'],
        type: 'unique',
        name: 'unique_sales_agent_commission_contract',
        transaction,
      });

      await queryInterface.addIndex('sales_agent_commissions', ['commissionPlanId'], { transaction });
      await queryInterface.addIndex('sales_agent_commissions', ['parentCommissionId'], { transaction });
      await queryInterface.addIndex('sales_agent_commissions', ['kind'], { transaction });

      await transaction.commit();
    } catch (err) {
      await transaction.rollback();
      throw err;
    }
  },

  async down(queryInterface, Sequelize) {
    const { DataTypes } = Sequelize;
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.removeIndex('sales_agent_commissions', ['kind'], { transaction });
      await queryInterface.removeIndex('sales_agent_commissions', ['parentCommissionId'], { transaction });
      await queryInterface.removeIndex('sales_agent_commissions', ['commissionPlanId'], { transaction });
      await queryInterface.removeConstraint(
        'sales_agent_commissions',
        'unique_sales_agent_commission_contract',
        { transaction },
      );

      await queryInterface.changeColumn(
        'sales_agent_commissions',
        'totalInstallments',
        { type: DataTypes.INTEGER, allowNull: false },
        { transaction },
      );
      await queryInterface.changeColumn(
        'sales_agent_commissions',
        'commissionMonths',
        { type: DataTypes.INTEGER, allowNull: false },
        { transaction },
      );
      await queryInterface.changeColumn(
        'sales_agent_commissions',
        'endDate',
        { type: DataTypes.DATEONLY, allowNull: false },
        { transaction },
      );
      await queryInterface.changeColumn(
        'sales_agent_commissions',
        'percent',
        { type: DataTypes.DECIMAL(5, 2), allowNull: false },
        { transaction },
      );
      await queryInterface.changeColumn(
        'sales_agent_commissions',
        'status',
        {
          type: DataTypes.ENUM('pending', 'active', 'completed', 'cancelled'),
          allowNull: false,
          defaultValue: 'active',
        },
        { transaction },
      );

      await queryInterface.removeColumn('sales_agent_commissions', 'parentCommissionId', { transaction });
      await queryInterface.removeColumn('sales_agent_commissions', 'kind', { transaction });
      await queryInterface.removeColumn('sales_agent_commissions', 'hardEndDate', { transaction });
      await queryInterface.removeColumn('sales_agent_commissions', 'totalUnits', { transaction });
      await queryInterface.removeColumn('sales_agent_commissions', 'tierBasis', { transaction });
      await queryInterface.removeColumn('sales_agent_commissions', 'basis', { transaction });
      await queryInterface.removeColumn('sales_agent_commissions', 'commissionPlanId', { transaction });

      await transaction.commit();
    } catch (err) {
      await transaction.rollback();
      throw err;
    }
  },
};
