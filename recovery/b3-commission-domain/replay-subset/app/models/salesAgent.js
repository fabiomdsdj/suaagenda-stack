module.exports = (sequelize, DataTypes) => {
  const SalesAgent = sequelize.define('SalesAgent', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
      allowNull: false,
    },

    // ✅ NOVO: quantos meses o agente recebe comissão após a assinatura do tenant
    // Ex: 12 = recebe por 12 meses a partir da data da assinatura
    commissionMonths: {
      type: DataTypes.INTEGER,
      allowNull: true,
      defaultValue: 12,
    },

    // Dados bancários
    bankName:      DataTypes.STRING,
    bankCode:      DataTypes.STRING,
    agency:        DataTypes.STRING,
    agencyDigit:   DataTypes.STRING,
    accountNumber: DataTypes.STRING,
    accountDigit:  DataTypes.STRING,
    accountType: {
      type: DataTypes.ENUM('checking', 'savings', 'pix'),
    },
    pixKey: DataTypes.STRING,

    salesAgentStatusId: DataTypes.INTEGER,
    salesAgentPaiId: {
      type: DataTypes.UUID,
      allowNull: true,
    },
  }, {
    tableName: 'sales_agents',
  });

  SalesAgent.associate = models => {
    SalesAgent.hasMany(models.Tenant, {
      foreignKey: 'salesAgentId',
      as: 'salesAgent',
    });

    SalesAgent.belongsTo(models.User, {
      foreignKey: 'userId',
      as: 'salesAgentUser',
    });

    SalesAgent.belongsTo(models.SalesAgentStatus, {
      foreignKey: 'salesAgentStatusId',
      as: 'statusDetails',
    });

    SalesAgent.hasMany(models.SalesAgentOverride, {
      foreignKey: 'salesAgentId',
    });

    // Hierarquia pai/filhos
    SalesAgent.belongsTo(SalesAgent, {
      as: 'pai',
      foreignKey: 'salesAgentPaiId',
    });
    SalesAgent.hasMany(SalesAgent, {
      as: 'filhos',
      foreignKey: 'salesAgentPaiId',
    });

    // ✅ NOVO: comissões desse agente (uma por tenant assinante)
    SalesAgent.hasMany(models.SalesAgentCommission, {
      foreignKey: 'salesAgentId',
      as: 'commissions',
    });
  };

  return SalesAgent;
};