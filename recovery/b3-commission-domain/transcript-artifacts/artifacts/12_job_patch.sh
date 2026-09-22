cd /home/fabiomdsdj/Documents/sistema/suaagenda-stack/api && python3 - <<'PY'
import io
p='app/jobs/commissionJob.js'
s=io.open(p,encoding='utf-8').read()

old = """// Este job NÃO está registrado em nenhum cron (não estava antes e continua não
// estando — agendar é decisão de outro ciclo). Ainda assim ele é idempotente:
// reexecutar, ou rodar dois workers ao mesmo tempo, não duplica repasse — os
// row locks e as validações dentro da transaction são do `commissionPayout`.
"""

new = """// Este job NÃO está registrado em nenhum cron (não estava antes e continua não
// estando — agendar é decisão de outro ciclo).
//
// IDEMPOTÊNCIA — o que vale e onde para:
//   O COMMIT CONTÁBIL é idempotente. Reexecutar o job, ou rodar dois workers
//   ao mesmo tempo, não marca o mesmo lançamento como approved/paid duas
//   vezes: os row locks e a revalidação dentro da transaction são do
//   `commissionPayout`, e o worker perdedor falha alto sem escrever.
//   A LIQUIDAÇÃO EXTERNA não é. Em 'external', dois workers concorrentes
//   podem ler a mesma fila `approved` e disparar DUAS transferências antes de
//   qualquer um marcar `paid` — a transferência acontece fora da transaction
//   e não deixa estado persistido. Enquanto a lacuna acima não for fechada,
//   'external' pressupõe UM worker por vez.
"""

assert old in s
s = s.replace(old, new)
io.open(p,'w',encoding='utf-8').write(s)
print("ok")
PY
node -e "require('./app/jobs/commissionJob.js'); console.log('parse OK')"