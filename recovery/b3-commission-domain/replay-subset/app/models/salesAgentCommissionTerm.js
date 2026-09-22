// SNAPSHOT IMUTÁVEL das faixas contratadas.
//
// Copiado de CommissionPlanTier no momento em que o contrato é criado.
// A partir daí o contrato é lido daqui, nunca do plano — alterar ou desativar
// o plano não pode mudar o que já foi acordado.
module.exports = (sequelize, DataTypes) => {
  const SalesAgentCommissionTerm = sequelize.define('SalesAgentCommissionTerm', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
      allowNull: false,
    },

    salesAgentCommissionId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: { model: 'sales_agent_commissions', key: 'id' },
    },

    tierOrder: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },

    fromUnit: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },

    // NULL = faixa aberta até o fim do contrato
    toUnit: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },

    percent: {
      type: DataTypes.DECIMAL(5, 2),
      allowNull: false,
    },
  }, {
    tableName: 'sales_agent_commission_terms',
  });

  SalesAgentCommissionTerm.associate = (models) => {
    SalesAgentCommissionTerm.belongsTo(models.SalesAgentCommission, {
      foreignKey: 'salesAgentCommissionId',
      as: 'commission',
    });

    SalesAgentCommissionTerm.hasMany(models.SalesAgentCommissionInstallment, {
      foreignKey: 'termId',
      as: 'installments',
    });
  };

  return SalesAgentCommissionTerm;
};
