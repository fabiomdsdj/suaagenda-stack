'use strict';

/** ──────────────────────────────────────────────────────────────────────────
 * Model: CommissionEntry
 *
 * Representa UMA entrada de comissão gerada para um Employee em determinado
 * mês de referência.
 *
 * Relacionamentos:
 *   CommissionEntry  →  Employee     (belongsTo employeeId)
 *   CommissionEntry  →  Signature    (belongsTo signatureId) [opcional]
 *   CommissionEntry  →  Tenant       (belongsTo tenantId)
 * ─────────────────────────────────────────────────────────────────────────*/

module.exports = (sequelize, DataTypes) => {
  const CommissionEntry = sequelize.define(
    'CommissionEntry',
    {
      tenantId: {
        type: DataTypes.INTEGER,
        allowNull: false,
      },

      // FK principal — funcionário que recebe a comissão
      employeeId: {
        type: DataTypes.INTEGER,
        allowNull: true, // nullable para compatibilidade com registros legados
      },

      // Mantido para compatibilidade com o módulo de salesAgent
      salesAgentId: {
        type: DataTypes.INTEGER,
        allowNull: true,
      },

      // Assinatura/venda que originou esta comissão (opcional)
      signatureId: {
        type: DataTypes.INTEGER,
        allowNull: true,
      },

      // "2026-03" — facilita GROUP BY por mês sem depender de funções de data
      referenceMonth: {
        type: DataTypes.STRING(7),
        allowNull: false,
        validate: {
          is: /^\d{4}-\d{2}$/,
        },
      },

      // Valor base sobre o qual a comissão foi calculada
      subscriptionFee: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: false,
        defaultValue: 0,
      },

      // % copiado da Comission config no momento da geração (histórico imutável)
      commissionPercent: {
        type: DataTypes.DECIMAL(5, 2),
        allowNull: false,
      },

      // Valor final = subscriptionFee * commissionPercent / 100
      commissionAmount: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: false,
        defaultValue: 0,
      },

      // 'pending' | 'paid' | 'cancelled'
      status: {
        type: DataTypes.STRING(20),
        allowNull: false,
        defaultValue: 'pending',
        validate: {
          isIn: [['pending', 'paid', 'cancelled']],
        },
      },

      // Preenchido quando status → 'paid'
      paidAt: {
        type: DataTypes.DATE,
        allowNull: true,
      },

      notes: {
        type: DataTypes.TEXT,
        allowNull: true,
      },
    },
    {
      tableName: 'commission_entries',
      timestamps: true,
    }
  );

  CommissionEntry.associate = (models) => {
    CommissionEntry.belongsTo(models.Employee, {
      foreignKey: 'employeeId',
      as: 'employee',
    });

    CommissionEntry.belongsTo(models.SalesAgent, {
      foreignKey: 'salesAgentId',
      as: 'salesAgent',
    });

    if (models.Signature) {
      CommissionEntry.belongsTo(models.Signature, {
        foreignKey: 'signatureId',
        as: 'signature',
      });
    }

    CommissionEntry.belongsTo(models.Tenant, {
      foreignKey: 'tenantId',
      as: 'tenant',
    });
  };

  return CommissionEntry;
};

  