// Lançamento de comissão do agente.
//
// A partir de B3.4 deixa de ser "parcela N de M" e passa a ser um LANÇAMENTO:
// crédito ou estorno, amarrado à faixa (termId) que o originou e ao pagamento
// (paymentId) que o disparou. paymentId NÃO é mais único globalmente — o mesmo
// pagamento pode render lançamentos em contratos e faixas diferentes.
module.exports = (sequelize, DataTypes) => {
  const SalesAgentCommissionInstallment = sequelize.define('SalesAgentCommissionInstallment', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
      allowNull: false,
    },

    // Número sequencial do lançamento dentro do contrato
    installmentNumber: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },

    // paymentId do Asaas. A unicidade agora é composta:
    // (salesAgentCommissionId, paymentId, termId, entryType)
    paymentId: {
      type: DataTypes.STRING,
      allowNull: false,
    },

    referenceMonth: {
      type: DataTypes.STRING, // "2026-02"
      allowNull: false
    },

    approvedAt: {
      type: DataTypes.DATE,
      allowNull: true
    },

    // Data em que o repasse foi efetivamente pago ao agente
    paidAt: {
      type: DataTypes.DATE,
      allowNull: true
    },

    // Valor em R$ do lançamento
    amount: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
    },

    dueDate: {
      type: DataTypes.DATEONLY,
      allowNull: false,
    },

    status: {
      type: DataTypes.ENUM('pending', 'approved', 'paid', 'cancelled'),
      defaultValue: 'pending',
      allowNull: false,
    },

    salesAgentCommissionId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: { model: 'sales_agent_commissions', key: 'id' },
    },

    // Faixa contratada (snapshot) que originou o lançamento
    termId: {
      type: DataTypes.UUID,
      allowNull: true,
      references: { model: 'sales_agent_commission_terms', key: 'id' },
    },

    // --- Contexto do pagamento do cliente ---

    paymentDate: {
      type: DataTypes.DATE,
      allowNull: true,
    },

    billingCycle: {
      type: DataTypes.ENUM('monthly', 'quarterly', 'annual'),
      allowNull: true,
    },

    // --- Unidades cobertas por esse lançamento ---

    unitFrom: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },

    unitTo: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },

    unitsCovered: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },

    // --- Memória de cálculo: amount = baseAmount * percentApplied / 100 ---

    baseAmount: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: true,
    },

    percentApplied: {
      type: DataTypes.DECIMAL(5, 2),
      allowNull: true,
    },

    // --- Estorno ---

    entryType: {
      type: DataTypes.ENUM('credit', 'reversal'),
      allowNull: false,
      defaultValue: 'credit',
    },

    // Crédito que esse estorno anula. Lógica de refund NÃO implementada neste ciclo.
    reversalOfId: {
      type: DataTypes.UUID,
      allowNull: true,
      references: { model: 'sales_agent_commission_installments', key: 'id' },
    },

    // --- Repasse ao agente ---

    payoutDueDate: {
      type: DataTypes.DATEONLY,
      allowNull: true,
    },

    payoutBatchId: {
      type: DataTypes.STRING,
      allowNull: true,
    },
  }, {
    tableName: 'sales_agent_commission_installments',
  });

  SalesAgentCommissionInstallment.associate = (models) => {
    SalesAgentCommissionInstallment.belongsTo(models.SalesAgentCommission, {
      foreignKey: 'salesAgentCommissionId',
      as: 'commission',
    });

    SalesAgentCommissionInstallment.belongsTo(models.SalesAgentCommissionTerm, {
      foreignKey: 'termId',
      as: 'term',
    });

    // Auto-relacionamento de estorno
    SalesAgentCommissionInstallment.belongsTo(SalesAgentCommissionInstallment, {
      foreignKey: 'reversalOfId',
      as: 'reversalOf',
    });
    SalesAgentCommissionInstallment.hasMany(SalesAgentCommissionInstallment, {
      foreignKey: 'reversalOfId',
      as: 'reversals',
    });
  };

  return SalesAgentCommissionInstallment;
};
