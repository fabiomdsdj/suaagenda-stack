// Template reutilizável de comissão de agente de vendas.
//
// O plano é só um MOLDE. Quando um contrato (SalesAgentCommission) é fechado,
// as faixas são copiadas para SalesAgentCommissionTerm e o contrato passa a
// viver da própria cópia — mudar o plano depois não mexe em contrato fechado.
module.exports = (sequelize, DataTypes) => {
  const CommissionPlan = sequelize.define('CommissionPlan', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
      allowNull: false,
    },

    name: {
      type: DataTypes.STRING,
      allowNull: false,
    },

    description: {
      type: DataTypes.STRING,
      allowNull: true,
    },

    // Sobre o que a "unidade" é contada:
    //  billing_month → cada mês de vigência da assinatura
    //  payment       → cada pagamento efetivamente recebido
    basis: {
      type: DataTypes.ENUM('billing_month', 'payment'),
      allowNull: false,
      defaultValue: 'billing_month',
    },

    // sequence → faixas percorridas pela ordem das unidades (1ª, 2ª, 3ª...)
    // volume   → RESERVADO. Campo existe, mas não é implementado neste ciclo.
    tierBasis: {
      type: DataTypes.ENUM('sequence', 'volume'),
      allowNull: false,
      defaultValue: 'sequence',
    },

    // NULL = ilimitado
    totalUnits: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },

    isActive: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
    },

    createdByUserId: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: { model: 'users', key: 'id' },
    },
  }, {
    tableName: 'commission_plans',
  });

  CommissionPlan.associate = (models) => {
    CommissionPlan.hasMany(models.CommissionPlanTier, {
      foreignKey: 'commissionPlanId',
      as: 'tiers',
    });

    CommissionPlan.belongsTo(models.User, {
      foreignKey: 'createdByUserId',
      as: 'createdByUser',
    });

    // Agentes que usam esse plano como padrão
    CommissionPlan.hasMany(models.SalesAgent, {
      foreignKey: 'defaultCommissionPlanId',
      as: 'salesAgents',
    });

    // Contratos gerados a partir desse plano
    CommissionPlan.hasMany(models.SalesAgentCommission, {
      foreignKey: 'commissionPlanId',
      as: 'commissions',
    });
  };

  return CommissionPlan;
};
