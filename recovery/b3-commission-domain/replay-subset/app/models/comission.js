module.exports = (sequelize, DataTypes) => {
  const Comission = sequelize.define('Comission', {
    percent: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
  },
  {
    tableName: 'comissions',
  });
    // creating associations
  Comission.associate = (models) => {
    // Employee with Comission
    Comission.hasMany(models.Employee, {
      as: 'comission',
      foreignKey: 'comissionId',
    });

    // Comission with Tenants
    Comission.belongsTo(models.Tenant, {
      foreignKey: 'tenantId',
    });

    Comission.belongsTo(models.ComissionType, {
      as: 'comissionType',
      foreignKey: 'comissionTypeId',
    });

    Comission.belongsTo(models.ComissionStatus, {
      as: 'comissionStatus',
      foreignKey: 'comissionStatusId',
    });
  };

  return Comission;
};
