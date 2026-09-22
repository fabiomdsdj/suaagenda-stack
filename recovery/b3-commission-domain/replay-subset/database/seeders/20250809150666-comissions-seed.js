'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    const now = new Date();
    const formattedNow = now.toISOString().slice(0, 19).replace('T', ' ');

    // -----------------------------
    // Tipos de Comissão
    // -----------------------------
    const comissionTypes = [
      { name: 'percent', label: 'Porcentagem', createdAt: formattedNow, updatedAt: formattedNow },
      { name: 'fixed', label: 'Fixa', createdAt: formattedNow, updatedAt: formattedNow },
    ];
    await queryInterface.bulkInsert('comission_types', comissionTypes);

    const [typeRows] = await queryInterface.sequelize.query(
      'SELECT id, name FROM comission_types'
    );
    const typeMap = {};
    typeRows.forEach(t => { typeMap[t.name] = t.id; });

    // -----------------------------
    // Status de Comissão
    // -----------------------------
    const comissionStatus = [
      { name: 'active', label: 'Ativa', createdAt: formattedNow, updatedAt: formattedNow },
      { name: 'inactive', label: 'Inativa', createdAt: formattedNow, updatedAt: formattedNow },
    ];
    await queryInterface.bulkInsert('comission_status', comissionStatus);

    const [statusRows] = await queryInterface.sequelize.query(
      'SELECT id, name FROM comission_status'
    );
    const statusMap = {};
    statusRows.forEach(s => { statusMap[s.name] = s.id; });

    // -----------------------------
    // Comissões
    // -----------------------------
    const comissions = [
      { percent: 80, comissionTypeId: typeMap['percent'], comissionStatusId: statusMap['active'], createdAt: formattedNow, updatedAt: formattedNow },
      { percent: 70, comissionTypeId: typeMap['percent'], comissionStatusId: statusMap['active'], createdAt: formattedNow, updatedAt: formattedNow },
      { percent: 60, comissionTypeId: typeMap['percent'], comissionStatusId: statusMap['active'], createdAt: formattedNow, updatedAt: formattedNow },
      { percent: 50, comissionTypeId: typeMap['percent'], comissionStatusId: statusMap['active'], createdAt: formattedNow, updatedAt: formattedNow },
      { percent: 40, comissionTypeId: typeMap['percent'], comissionStatusId: statusMap['active'], createdAt: formattedNow, updatedAt: formattedNow },
      { percent: 30, comissionTypeId: typeMap['percent'], comissionStatusId: statusMap['active'], createdAt: formattedNow, updatedAt: formattedNow },
      { percent: 20, comissionTypeId: typeMap['percent'], comissionStatusId: statusMap['active'], createdAt: formattedNow, updatedAt: formattedNow },
      { percent: 10, comissionTypeId: typeMap['percent'], comissionStatusId: statusMap['active'], createdAt: formattedNow, updatedAt: formattedNow },
      { percent:  5, comissionTypeId: typeMap['percent'], comissionStatusId: statusMap['active'], createdAt: formattedNow, updatedAt: formattedNow },
    ];
    await queryInterface.bulkInsert('comissions', comissions);

    // -----------------------------
    // Aplicar Employees
    // -----------------------------
    const [employeeRows] = await queryInterface.sequelize.query(
      'SELECT id FROM employees ORDER BY id'
    );

    // Pegamos os IDs das comissões recém-criadas
    const [comissionRows] = await queryInterface.sequelize.query('SELECT id FROM comissions ORDER BY id');

    const employeeComissions = employeeRows.map((e, i) => ({
      employeeId: e.id,
      comissionId: comissionRows[i % comissionRows.length].id,
    }));

    // Atualiza os employees
    for (const ec of employeeComissions) {
      await queryInterface.sequelize.query(
        `UPDATE employees SET comissionId = ${ec.comissionId}, updatedAt='${formattedNow}' WHERE id = ${ec.employeeId}`
      );
    }
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.bulkDelete('comissions', null, {});
    await queryInterface.bulkDelete('comission_types', null, {});
    await queryInterface.bulkDelete('comission_status', null, {});
  }
};
