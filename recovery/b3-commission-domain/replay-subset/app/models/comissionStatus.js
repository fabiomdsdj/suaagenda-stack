module.exports = (sequelize, DataTypes) => {
  const ComissionStatus = sequelize.define('ComissionStatus', {
    name: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    label: {
      type: DataTypes.STRING,
    },
  },
  {
    tableName: 'comission_status',
  });
    // creating associations
  ComissionStatus.associate = (models) => {
    // Employee with Comission
    ComissionStatus.hasMany(models.Comission, {
      as: 'comissionStatus',
      foreignKey: 'comissionStatusId',
    });
  };

  return ComissionStatus;
};
