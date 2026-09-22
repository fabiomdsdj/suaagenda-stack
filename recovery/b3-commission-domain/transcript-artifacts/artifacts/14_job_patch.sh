python3 - <<'PY'
import io
p='app/jobs/commissionJob.js'
s=io.open(p,encoding='utf-8').read()

old = """// ---------------------------------------------------------------------------
// Fora de escopo neste ciclo: payoutDueDate (nunca escrito nem lido aqui),
// dashboard/ledger (`salesAgent.controller.js` soma `amount` sem filtrar
// `entryType` — divergência conhecida, fica para B3.9), CRUD de planos,
// frontend, recuperação de comissão paga e depois estornada, novas migrations.
//
"""

new = """// ---------------------------------------------------------------------------
// FORA DE ESCOPO NESTE CICLO — registrado aqui para não se perder
// ---------------------------------------------------------------------------
//   • payoutDueDate: continua NUNCA preenchido. Este job não o escreve nem o
//     lê; a regra de vencimento do repasse é ciclo próprio. A carência de
//     aprovação usa `dueDate` (ver DEFAULT_APPROVAL_HOLD_DAYS).
//
//   • B3.9 — dashboard/ledger: `app/controllers/salesAgent.controller.js` soma
//     `amount` sem filtrar `entryType`, então os estornos (amount negativo)
//     entram no mesmo balde dos créditos. Isso diverge de
//     `summarizeInstallments`, que separa crédito de estorno. NÃO corrigido
//     aqui — é ciclo próprio de dashboard/ledger.
//
//   • Cleanup — `app/services/salesAgentComission.js`: código legado morto.
//     Referencia models que não existem (`SalesAgentComission`,
//     `SalesAgentComissionInstallment` — sem o dobro de 'm'), tem um
//     `payInstallment()` próprio e mexe em `paidInstallments`. Nenhum arquivo
//     do projeto o importa, e este job NÃO o usa. Candidato a remoção em
//     cleanup separado; deixado no lugar para não ampliar o escopo daqui.
//
//   • Também fora: CRUD de planos, frontend, payout manual por UI, recuperação
//     de comissão paga e depois estornada, override pai/filho, tiers por
//     volume, versionamento de plano, comissão de funcionário, NFS-e, wallet,
//     novas migrations, agendamento em produção.
//
"""

assert old in s
io.open(p,'w',encoding='utf-8').write(s.replace(old,new))
print('ok')
PY
node -e "require('./app/jobs/commissionJob.js'); console.log('parse OK')"