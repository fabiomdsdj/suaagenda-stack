// Carrega os models Sequelize sem passar por app/models/index.js.
//
// index.js varre o diretório inteiro e acaba exigindo session.js, que é um
// model do MONGOOSE, não do Sequelize. Em runtime isso passa batido, mas sob
// o Jest 26 deste projeto o mongoose quebra no require de `node:async_hooks`
// (o resolver do Jest 26 não conhece o prefixo `node:`), derrubando qualquer
// suíte que toque em app/models.
//
// Aqui montamos o mesmo registry, pulando os arquivos que não são factories
// do Sequelize.
const fs = require('fs');
const path = require('path');
const { Sequelize, DataTypes } = require('sequelize');

const MODELS_DIR = path.join(__dirname, '..', '..', 'app', 'models');
const SKIP = new Set(['index.js', 'session.js']);

function loadModels() {
  const env = process.env.NODE_ENV || 'development';
  const config = require('../../config/database')[env];

  const sequelize = new Sequelize(config.database, config.username, config.password, {
    host: config.host,
    port: config.port,
    dialect: config.dialect,
    dialectOptions: config.dialectOptions,
    logging: false,
  });

  const db = {};

  fs.readdirSync(MODELS_DIR)
    .filter((file) => file.slice(-3) === '.js' && !SKIP.has(file))
    .forEach((file) => {
      const model = require(path.join(MODELS_DIR, file))(sequelize, DataTypes);
      db[model.name] = model;
    });

  Object.keys(db).forEach((name) => {
    if (db[name].associate) db[name].associate(db);
  });

  db.sequelize = sequelize;
  db.Sequelize = Sequelize;

  return db;
}

module.exports = { loadModels };
