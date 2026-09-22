module.exports = (sequelize, DataTypes) => {
  const SalesAgentCommission = sequelize.define('SalesAgentCommission', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
      allowNull: false,
    },

    // Percentual negociado com esse agente para esse tenant
    percent: {
      type: DataTypes.DECIMAL(5, 2),
      allowNull: false,
    },

    // Data em que a comissão começa a ser contada (= data da assinatura)
    startDate: {
      type: DataTypes.DATEONLY,
      allowNull: false,
    },

    // Data calculada: startDate + commissionMonths do SalesAgent
    // Ex: startDate = 2025-01-01, commissionMonths = 12 → endDate = 2025-12-31
    endDate: {
      type: DataTypes.DATEONLY,
      allowNull: false,
    },

    // Quantos meses de comissão esse agente tem direito (copiado do SalesAgent no momento da criação)
    // Guardamos aqui para ter histórico, já que o valor no SalesAgent pode mudar
    commissionMonths: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },

    // Quantas parcelas já foram pagas ao agente
    paidInstallments: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
      allowNull: false,
    },

    // Total de parcelas que o agente vai receber
    // Plano mensal → igual a commissionMonths
    // Plano anual  → 1 parcela (valor = percent * 12 meses de receita)
    // Plano trimestral → commissionMonths / 3 parcelas
    totalInstallments: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },

    // Status: pending | active | completed | cancelled
    status: {
      type: DataTypes.ENUM('pending', 'active', 'completed', 'cancelled'),
      defaultValue: 'active',
      allowNull: false,
    },

    // FKs
    salesAgentId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: { model: 'sales_agents', key: 'id' },
    },
    tenantId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: { model: 'tenants', key: 'id' },
    },
    signatureId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: { model: 'signatures', key: 'id' },
    },
  }, {
    tableName: 'sales_agent_commissions',
  });

  SalesAgentCommission.associate = (models) => {
    SalesAgentCommission.belongsTo(models.SalesAgent, {
      foreignKey: 'salesAgentId',
      as: 'salesAgent',
    });
    SalesAgentCommission.belongsTo(models.Tenant, {
      foreignKey: 'tenantId',
      as: 'tenant',
    });
    SalesAgentCommission.belongsTo(models.Signature, {
      foreignKey: 'signatureId',
      as: 'signature',
    });

    // Parcelas individuais geradas para esse agente nessa comissão
    SalesAgentCommission.hasMany(models.SalesAgentCommissionInstallment, {
      foreignKey: 'salesAgentCommissionId',
      as: 'installments',
    });
  };

  return SalesAgentCommission;
};