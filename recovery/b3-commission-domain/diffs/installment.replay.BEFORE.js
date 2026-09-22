module.exports = (sequelize, DataTypes) => {
  const SalesAgentCommissionInstallment = sequelize.define('SalesAgentCommissionInstallment', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
      allowNull: false,
    },

    // Número da parcela: 1, 2, 3 ... commissionMonths
    installmentNumber: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },

    //paymentId do Asaas
    paymentId: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true
    },   
    
    referenceMonth: {
      type: DataTypes.STRING, // "2026-02"
      allowNull: false
    },
    
    approvedAt: {
      type: DataTypes.DATE,
      allowNull: true
    },
    
    paidAt: {
      type: DataTypes.DATE,
      allowNull: true
    },

    // Valor em R$ a ser pago ao agente nessa parcela
    amount: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
    },

    // Data prevista para pagamento (startDate + N meses)
    dueDate: {
      type: DataTypes.DATEONLY,
      allowNull: false,
    },

    // Status: pending | paid | cancelled
    status: {
      type: DataTypes.ENUM('pending', 'paid', 'cancelled'),
      defaultValue: 'pending',
      allowNull: false,
    },

    salesAgentCommissionId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: { model: 'sales_agent_commissions', key: 'id' },
    },
  }, {
    tableName: 'sales_agent_commission_installments',
  });

  SalesAgentCommissionInstallment.associate = (models) => {
    SalesAgentCommissionInstallment.belongsTo(models.SalesAgentCommission, {
      foreignKey: 'salesAgentCommissionId',
      as: 'commission',
    });
  };

  return SalesAgentCommissionInstallment;
};