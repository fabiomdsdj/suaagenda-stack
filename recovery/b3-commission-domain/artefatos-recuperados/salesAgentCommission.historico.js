// Contrato de comissão de um agente sobre uma assinatura de um tenant.
//
// A partir do modelo de planos (B3.4), a regra vive nas faixas contratadas
// (SalesAgentCommissionTerm) + basis/tierBasis/totalUnits/hardEndDate.
// Os campos percent, commissionMonths, totalInstallments, paidInstallments e
// endDate estão APOSENTADOS: continuam na tabela pelo código legado, mas a
// nova regra não depende deles.
module.exports = (sequelize, DataTypes) => {
  const SalesAgentCommission = sequelize.define('SalesAgentCommission', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
      allowNull: false,
    },

    // ⚠️ DEPRECADO — use as faixas em SalesAgentCommissionTerm
    percent: {
      type: DataTypes.DECIMAL(5, 2),
      allowNull: true,
    },

    // Data em que a comissão começa a ser contada (= data da assinatura)
    startDate: {
      type: DataTypes.DATEONLY,
      allowNull: false,
    },

    // ⚠️ DEPRECADO — use totalUnits / hardEndDate
    endDate: {
      type: DataTypes.DATEONLY,
      allowNull: true,
    },

    // ⚠️ DEPRECADO — use totalUnits
    commissionMonths: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },

    // ⚠️ DEPRECADO — derivado das parcelas
    paidInstallments: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
      allowNull: false,
    },

    // ⚠️ DEPRECADO — derivado das parcelas
    totalInstallments: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },

    status: {
      type: DataTypes.ENUM('active', 'suspended', 'completed', 'cancelled'),
      defaultValue: 'active',
      allowNull: false,
    },

    // --- Snapshot das regras de topo, copiado do plano na contratação ---

    commissionPlanId: {
      type: DataTypes.UUID,
      allowNull: true,
      references: { model: 'commission_plans', key: 'id' },
    },

    basis: {
      type: DataTypes.ENUM('billing_month', 'payment'),
      allowNull: false,
      defaultValue: 'billing_month',
    },

    // 'volume' reservado, não implementado neste ciclo
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

    // Corte duro opcional: nada é gerado depois dessa data
    hardEndDate: {
      type: DataTypes.DATEONLY,
      allowNull: true,
    },

    // direct   = agente que vendeu
    // override = comissão do agente pai sobre a mesma venda
    kind: {
      type: DataTypes.ENUM('direct', 'override'),
      allowNull: false,
      defaultValue: 'direct',
    },

    // Contrato direct que originou esse override.
    // A lógica pai/filho NÃO é implementada neste ciclo.
    parentCommissionId: {
      type: DataTypes.UUID,
      allowNull: true,
      references: { model: 'sales_agent_commissions', key: 'id' },
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

    SalesAgentCommission.belongsTo(models.CommissionPlan, {
      foreignKey: 'commissionPlanId',
      as: 'commissionPlan',
    });

    // Snapshot imutável das faixas contratadas
    SalesAgentCommission.hasMany(models.SalesAgentCommissionTerm, {
      foreignKey: 'salesAgentCommissionId',
      as: 'terms',
    });

    // Hierarquia direct → override
    SalesAgentCommission.belongsTo(SalesAgentCommission, {
      foreignKey: 'parentCommissionId',
      as: 'parentCommission',
    });
    SalesAgentCommission.hasMany(SalesAgentCommission, {
      foreignKey: 'parentCommissionId',
      as: 'childCommissions',
    });

    // Parcelas individuais geradas para esse agente nessa comissão
    SalesAgentCommission.hasMany(models.SalesAgentCommissionInstallment, {
      foreignKey: 'salesAgentCommissionId',
      as: 'installments',
    });
  };

  return SalesAgentCommission;
};
