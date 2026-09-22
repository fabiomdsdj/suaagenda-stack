const { loadModels } = require('./__tests__/utils/sequelizeModels');
const db = loadModels();

const I = db.SalesAgentCommissionInstallment;
const C = db.SalesAgentCommission;
const T = db.SalesAgentCommissionTerm;

const REQUIRED = ['paymentDate','billingCycle','unitFrom','unitTo','unitsCovered',
  'baseAmount','percentApplied','entryType','reversalOfId','payoutDueDate','payoutBatchId'];

console.log('=== INSTALLMENT rawAttributes ===');
const attrs = Object.keys(I.rawAttributes);
console.log(attrs.join(', '));
console.log('\n=== 11 COLUNAS EXIGIDAS ===');
let missing = [];
for (const c of REQUIRED) {
  const ok = attrs.includes(c);
  if (!ok) missing.push(c);
  console.log(`${ok ? 'OK  ' : 'FALTA'}  ${c}${ok ? '  -> ' + (I.rawAttributes[c].type.toString()) : ''}`);
}
console.log('\ntermId presente:', attrs.includes('termId'), attrs.includes('termId') ? '-> ' + I.rawAttributes.termId.type.toString() : '');
console.log('status type:', I.rawAttributes.status.type.toString());
console.log('paymentId unique:', I.rawAttributes.paymentId.unique);

const assocNames = (M) => Object.keys(M.associations);
console.log('\n=== ASSOCIACOES ===');
console.log('SalesAgentCommissionInstallment:', assocNames(I).join(', '));
console.log('SalesAgentCommission           :', assocNames(C).join(', '));
console.log('SalesAgentCommissionTerm       :', assocNames(T).join(', '));

const need = ['term','commission','reversalOf','reversals'];
let missA = need.filter(a => !assocNames(I).includes(a));
console.log('\n=== DETALHE ASSOC INSTALLMENT ===');
for (const [k,v] of Object.entries(I.associations)) {
  console.log(`  ${k}: ${v.associationType} -> ${v.target.name} (fk=${v.foreignKey})`);
}
console.log('\n=== DETALHE ASSOC COMMISSION ===');
for (const [k,v] of Object.entries(C.associations)) {
  console.log(`  ${k}: ${v.associationType} -> ${v.target.name} (fk=${v.foreignKey})`);
}
console.log('\n=== DETALHE ASSOC TERM ===');
for (const [k,v] of Object.entries(T.associations)) {
  console.log(`  ${k}: ${v.associationType} -> ${v.target.name} (fk=${v.foreignKey})`);
}

console.log('\n=== RESULTADO ===');
console.log('colunas faltando :', missing.length ? missing.join(', ') : 'NENHUMA');
console.log('assoc faltando   :', missA.length ? missA.join(', ') : 'NENHUMA');
process.exit(missing.length || missA.length ? 1 : 0);
