// Faixa de percentual dentro de um CommissionPlan.
// Ex: unidades 1-3 → 40%, 4-12 → 20%, 13+ → 10%.
module.exports = (sequelize, DataTypes) => {
  const CommissionPlanTier = sequelize.define('CommissionPlanTier', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
      allowNull: false,
    },

    commissionPlanId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: { model: 'commission_plans', key: 'id' },
    },

    tierOrder: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },

    fromUnit: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },

    // NULL = faixa aberta até o fim
    toUnit: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },

    percent: {
      type: DataTypes.DECIMAL(5, 2),
      allowNull: false,
    },
  }, {
    tableName: 'commission_plan_tiers',
  });

  CommissionPlanTier.associate = (models) => {
    CommissionPlanTier.belongsTo(models.CommissionPlan, {
      foreignKey: 'commissionPlanId',
      as: 'plan',
    });
  };

  return CommissionPlanTier;
};
