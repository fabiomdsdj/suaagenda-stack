python3 - <<'PY'
p='app/services/commissionEngine.js'
s=open(p).read()

old = """function processCommissionFromPayment(
  subscriptionId,
  value,
  paymentDate,
  paymentId,
  transaction,
) {
  if (!defaultEngine) {
    defaultEngine = buildEngine(require('../models'));
  }

  return defaultEngine.processCommissionFromPayment(
    subscriptionId,
    value,
    paymentDate,
    paymentId,
    transaction,
  );
}

module.exports = {
  processCommissionFromPayment,
  buildEngine,
  CommissionEngineError,
  // exportados para teste do cálculo puro
  buildSegments,
  allocateBases,
};"""

new = """function engine() {
  if (!defaultEngine) {
    defaultEngine = buildEngine(require('../models'));
  }
  return defaultEngine;
}

function processCommissionFromPayment(
  subscriptionId,
  value,
  paymentDate,
  paymentId,
  transaction,
) {
  return engine().processCommissionFromPayment(
    subscriptionId,
    value,
    paymentDate,
    paymentId,
    transaction,
  );
}

function reverseCommissionFromRefund(subscriptionId, paymentId, transaction) {
  return engine().reverseCommissionFromRefund(subscriptionId, paymentId, transaction);
}

module.exports = {
  processCommissionFromPayment,
  reverseCommissionFromRefund,
  buildEngine,
  CommissionEngineError,
  // exportados para teste do cálculo puro
  buildSegments,
  allocateBases,
};"""

assert old in s
s = s.replace(old, new, 1)
open(p,'w').write(s)
print('ok')
PY
node -e "const m=require('./app/services/commissionEngine'); console.log(Object.keys(m))"