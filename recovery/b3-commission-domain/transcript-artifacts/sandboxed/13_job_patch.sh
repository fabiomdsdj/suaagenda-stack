cd /tmp/claude-1000/-home-fabiomdsdj-Documents-sistema-suaagenda-stack/cc9798b5-cd03-4711-ba16-96ac95a2ca5a/scratchpad/b3.26/replay/api && python3 - <<'PY'
import io
p='app/services/commissionPayout.js'
s=io.open(p,encoding='utf-8').read()

old = """// NOTA SOBRE `app/jobs/commissionJob.js` — NÃO ALTERADO NESTE CICLO.
//
// O job hoje: (a) aprova em massa com um UPDATE direto, sem lock, sem olhar
// entryType e sem olhar estorno; (b) paga com aliases de association que não
// existem mais (`inst.SalesAgentCommission.SalesAgent`; o correto é
// `commission` / `salesAgent`); (c) dispara PIX no Asaas dentro da transaction
// e marca `paid` linha a linha, sem payoutBatchId. Ele está quebrado como
// está e será tratado em ciclo próprio.
//
// Quando for a vez dele, o job deve DELEGAR para este service:
//   approveInstallments(ids, t)        no lugar do UPDATE em massa
//   payApprovedInstallments(ids, t)    no lugar do update linha a linha
// selecionando os IDs com listApprovableInstallments / listPayableInstallments,
// que já filtram reversal, entryType e contrato cancelado.
"""

new = """// NOTA SOBRE `app/jobs/commissionJob.js` — CORRIGIDO EM B3.8.
//
// O job era quebrado: (a) aprovava em massa com um UPDATE direto, sem lock,
// sem olhar entryType e sem olhar estorno; (b) pagava com aliases de
// association que não existem mais (`inst.SalesAgentCommission.SalesAgent`;
// o correto é `commission` / `salesAgent`); (c) disparava PIX no Asaas DENTRO
// da transaction e marcava `paid` linha a linha, sem payoutBatchId.
//
// B3.8 reescreveu o job como orquestrador deste service: ele seleciona IDs com
// listApprovableInstallments / listPayableInstallments, agrupa por agente e
// chama approveInstallments / payApprovedInstallments dentro de transactions
// que ele mesmo abre. A liquidação externa ficou FORA da transaction e fora do
// caminho padrão — ver a "LACUNA CONHECIDA" no cabeçalho do job.
//
// Este service NÃO foi alterado por B3.8.
"""

assert old in s
io.open(p,'w',encoding='utf-8').write(s.replace(old,new))
print("ok")
PY
sed -i 's|^//   commissionJob (ver nota no fim do arquivo), integração bancária/PIX,$|//   integração bancária/PIX (o commissionJob de B3.8 orquestra este service,|;s|^//   workflow de cancelamento/ajuste, débito automático de comissão já paga,$|//   mas a liquidação externa continua fora daqui), workflow de\\n//   cancelamento/ajuste, débito automático de comissão já paga,|' app/services/commissionPayout.js
sed -n '18,26p' app/services/commissionPayout.js; node -e "require('./app/services/commissionPayout.js'); console.log('parse OK')"