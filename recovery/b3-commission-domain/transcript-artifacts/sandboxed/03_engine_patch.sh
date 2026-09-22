python3 - <<'PY'
import re
p='app/services/commissionEngine.js'
s=open(p).read()

old_header = """// ============================================================================
// COMMISSION ENGINE — B3.5
//"""
new_header = """// ============================================================================
// COMMISSION ENGINE — B3.5 (crédito) + B3.6 (reversal)
//"""
assert old_header in s
s = s.replace(old_header, new_header, 1)

old_scope = """// Fora de escopo neste ciclo (ver relatório B3.5):
//   PAYMENT_REFUNDED / reversal, payout, contratos override (pai/filho),
//   tierBasis 'volume', corte por hardEndDate.
// ============================================================================"""
new_scope = """// B3.6 acrescenta o caminho de ESTORNO (`reverseCommissionFromRefund`):
// um refund não apaga nem altera o crédito — lança um `reversal` espelhado,
// apontando para o crédito via `reversalOfId`, com `amount`/`baseAmount`
// negativos e o mesmo `unitsCovered`, de modo que o consumo derivado
// (SUM(credit) - SUM(reversal)) volte sozinho ao valor anterior.
//
// Fora de escopo neste ciclo (ver relatório B3.6):
//   payout, commissionJob, contratos override (pai/filho),
//   tierBasis 'volume', corte por hardEndDate.
// ============================================================================"""
assert old_scope in s
s = s.replace(old_scope, new_scope, 1)
open(p,'w').write(s)
print("header ok")
PY