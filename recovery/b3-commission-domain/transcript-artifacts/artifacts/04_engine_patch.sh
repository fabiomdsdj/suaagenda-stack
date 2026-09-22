python3 - <<'PY'
p='app/services/commissionEngine.js'
s=open(p).read()

# 1) helper de negação, junto dos helpers de dinheiro
anchor = """// Percentual guardado como DECIMAL(5,2) → basis points inteiros (40.00 → 4000)."""
helper = """// Espelha um DECIMAL(10,2) com o sinal invertido, sem passar por float solto.
// Usado no estorno: o reversal carrega exatamente o mesmo valor do crédito,
// negativo, para que a soma do razão do contrato feche em zero.
function negateAmount(value, context) {
  if (value === null || value === undefined) return null;

  const n = parseFloat(String(value));
  if (!Number.isFinite(n)) {
    throw new CommissionEngineError(`valor de lançamento inválido para estorno: ${value}`, context);
  }

  return centsToAmount(-Math.round(n * 100));
}

"""
assert anchor in s
s = s.replace(anchor, helper + anchor, 1)

open(p,'w').write(s)
print('ok')
PY