module.exports = (sequelize, DataTypes) => {
  const ComissionType = sequelize.define('ComissionType', {
    name: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    label: {
      type: DataTypes.STRING,
    },
  },
  {
    tableName: 'comission_types',
  });
    // creating associations
  ComissionType.associate = (models) => {
    // Employee with Comission
    ComissionType.hasMany(models.Comission, {
      as: 'comissionType',
      foreignKey: 'comissionTypeId',
    });
  };

  return ComissionType;
};
