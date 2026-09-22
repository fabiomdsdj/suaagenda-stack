'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    const { DataTypes } = Sequelize;
    const transaction = await queryInterface.sequelize.transaction();
    try {
      // ---------------------------------------------------------------
      // 1. Derruba a unicidade GLOBAL de paymentId.
      //    Um mesmo pagamento pode gerar lançamentos em contratos
      //    diferentes (direct + override) e em faixas diferentes.
      //    A migration original criou DOIS índices únicos sobre paymentId:
      //    `paymentId` (unique: true) e `unique_payment_commission`
      //    (addConstraint). Ambos precisam sair.
      // ---------------------------------------------------------------
      const indexes = await queryInterface.showIndex('sales_agent_commission_installments', {
        transaction,
      });

      for (const name of ['unique_payment_commission', 'paymentId']) {
        if (indexes.some((i) => i.name === name)) {
          await queryInterface.removeIndex('sales_agent_commission_installments', name, {
            transaction,
          });
        }
      }

      // ---------------------------------------------------------------
      // 2. Vínculo com a faixa contratada (snapshot)
      // ---------------------------------------------------------------
      await queryInterface.addColumn(
        'sales_agent_commission_installments',
        'termId',
        {
          type: DataTypes.UUID,
          allowNull: true,
          references: { model: 'sales_agent_commission_terms', key: 'id' },
          onUpdate: 'CASCADE',
          onDelete: 'RESTRICT',
          comment: 'Faixa (term) que originou esse lançamento',
        },
        { transaction },
      );

      // ---------------------------------------------------------------
      // 3. Contexto do pagamento que originou o lançamento
      // ---------------------------------------------------------------
      await queryInterface.addColumn(
        'sales_agent_commission_installments',
        'paymentDate',
        {
          type: DataTypes.DATE,
          allowNull: true,
          comment: 'Data do pagamento do cliente que originou o lançamento',
        },
        { transaction },
      );

      await queryInterface.addColumn(
        'sales_agent_commission_installments',
        'billingCycle',
        {
          type: DataTypes.ENUM('monthly', 'quarterly', 'annual'),
          allowNull: true,
          comment: 'Ciclo de cobrança da assinatura no momento do lançamento',
        },
        { transaction },
      );

      // ---------------------------------------------------------------
      // 4. Unidades cobertas por esse lançamento
      // ---------------------------------------------------------------
      await queryInterface.addColumn(
        'sales_agent_commission_installments',
        'unitFrom',
        { type: DataTypes.INTEGER, allowNull: true },
        { transaction },
      );

      await queryInterface.addColumn(
        'sales_agent_commission_installments',
        'unitTo',
        { type: DataTypes.INTEGER, allowNull: true },
        { transaction },
      );

      await queryInterface.addColumn(
        'sales_agent_commission_installments',
        'unitsCovered',
        { type: DataTypes.INTEGER, allowNull: true },
        { transaction },
      );

      // ---------------------------------------------------------------
      // 5. Memória de cálculo
      // ---------------------------------------------------------------
      await queryInterface.addColumn(
        'sales_agent_commission_installments',
        'baseAmount',
        {
          type: DataTypes.DECIMAL(10, 2),
          allowNull: true,
          comment: 'Base de cálculo usada: amount = baseAmount * percentApplied / 100',
        },
        { transaction },
      );

      await queryInterface.addColumn(
        'sales_agent_commission_installments',
        'percentApplied',
        { type: DataTypes.DECIMAL(5, 2), allowNull: true },
        { transaction },
      );

      // ---------------------------------------------------------------
      // 6. Estorno
      // ---------------------------------------------------------------
      await queryInterface.addColumn(
        'sales_agent_commission_installments',
        'entryType',
        {
          type: DataTypes.ENUM('credit', 'reversal'),
          allowNull: false,
          defaultValue: 'credit',
        },
        { transaction },
      );

      await queryInterface.addColumn(
        'sales_agent_commission_installments',
        'reversalOfId',
        {
          type: DataTypes.UUID,
          allowNull: true,
          references: { model: 'sales_agent_commission_installments', key: 'id' },
          onUpdate: 'CASCADE',
          onDelete: 'RESTRICT',
          comment: 'Lançamento de crédito que esse estorno anula. Lógica de refund NÃO implementada neste ciclo',
        },
        { transaction },
      );

      // ---------------------------------------------------------------
      // 7. Repasse ao agente
      // ---------------------------------------------------------------
      await queryInterface.addColumn(
        'sales_agent_commission_installments',
        'payoutDueDate',
        { type: DataTypes.DATEONLY, allowNull: true },
        { transaction },
      );

      await queryInterface.addColumn(
        'sales_agent_commission_installments',
        'payoutBatchId',
        { type: DataTypes.STRING, allowNull: true },
        { transaction },
      );

      // ---------------------------------------------------------------
      // 8. Status ganha o passo de aprovação
      // ---------------------------------------------------------------
      await queryInterface.changeColumn(
        'sales_agent_commission_installments',
        'status',
        {
          type: DataTypes.ENUM('pending', 'approved', 'paid', 'cancelled'),
          allowNull: false,
          defaultValue: 'pending',
        },
        { transaction },
      );

      // A migration original declarava `paidAt` duas vezes no createTable
      // (o literal JS deduplicou e só a 2ª, sem comment, chegou ao banco).
      // Normalizado aqui para uma definição única e documentada.
      await queryInterface.changeColumn(
        'sales_agent_commission_installments',
        'paidAt',
        {
          type: DataTypes.DATE,
          allowNull: true,
          comment: 'Data em que o repasse foi efetivamente pago ao agente',
        },
        { transaction },
      );

      // ---------------------------------------------------------------
      // 9. Nova idempotência: por contrato + pagamento + faixa + tipo
      // ---------------------------------------------------------------
      await queryInterface.addConstraint('sales_agent_commission_installments', {
        fields: ['salesAgentCommissionId', 'paymentId', 'termId', 'entryType'],
        type: 'unique',
        name: 'unique_commission_payment_term_entry',
        transaction,
      });

      await queryInterface.addIndex('sales_agent_commission_installments', ['termId'], { transaction });
      await queryInterface.addIndex('sales_agent_commission_installments', ['paymentId'], { transaction });
      await queryInterface.addIndex('sales_agent_commission_installments', ['reversalOfId'], { transaction });
      await queryInterface.addIndex('sales_agent_commission_installments', ['payoutBatchId'], { transaction });

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
      const table = 'sales_agent_commission_installments';

      await queryInterface.removeIndex(table, ['payoutBatchId'], { transaction });
      await queryInterface.removeIndex(table, ['reversalOfId'], { transaction });
      await queryInterface.removeIndex(table, ['paymentId'], { transaction });
      await queryInterface.removeIndex(table, ['termId'], { transaction });
      await queryInterface.removeConstraint(table, 'unique_commission_payment_term_entry', { transaction });

      await queryInterface.changeColumn(
        table,
        'status',
        {
          type: DataTypes.ENUM('pending', 'paid', 'cancelled'),
          allowNull: false,
          defaultValue: 'pending',
        },
        { transaction },
      );

      await queryInterface.removeColumn(table, 'payoutBatchId', { transaction });
      await queryInterface.removeColumn(table, 'payoutDueDate', { transaction });
      await queryInterface.removeColumn(table, 'reversalOfId', { transaction });
      await queryInterface.removeColumn(table, 'entryType', { transaction });
      await queryInterface.removeColumn(table, 'percentApplied', { transaction });
      await queryInterface.removeColumn(table, 'baseAmount', { transaction });
      await queryInterface.removeColumn(table, 'unitsCovered', { transaction });
      await queryInterface.removeColumn(table, 'unitTo', { transaction });
      await queryInterface.removeColumn(table, 'unitFrom', { transaction });
      await queryInterface.removeColumn(table, 'billingCycle', { transaction });
      await queryInterface.removeColumn(table, 'paymentDate', { transaction });
      await queryInterface.removeColumn(table, 'termId', { transaction });

      await queryInterface.addConstraint(table, {
        fields: ['paymentId'],
        type: 'unique',
        name: 'unique_payment_commission',
        transaction,
      });

      await transaction.commit();
    } catch (err) {
      await transaction.rollback();
      throw err;
    }
  },
};
