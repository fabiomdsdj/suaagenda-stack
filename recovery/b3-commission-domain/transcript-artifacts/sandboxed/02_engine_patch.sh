python3 - <<'PY'
import re
p='app/services/commissionEngine.js'
s=open(p).read()

# createDirectContract no longer reads paymentDateObj off context
s = s.replace(
  "  async function createDirectContract({ agent, tenant, signature, context }, transaction) {",
  "  async function createDirectContract({ agent, tenant, signature, paymentDateObj, context }, transaction) {")
s = s.replace(
  "      startDate: signature.start || format(context.paymentDateObj, 'yyyy-MM-dd'),",
  "      startDate: signature.start || format(paymentDateObj, 'yyyy-MM-dd'),")

s = s.replace(
  "      context.salesAgentId = agent.id;\n      context.paymentDateObj = toDate(paymentDate, context);\n",
  "      context.salesAgentId = agent.id;\n\n      const paymentDateObj = toDate(paymentDate, context);\n")

s = s.replace(
  "        contract = await createDirectContract({ agent, tenant, signature, context }, transaction);",
  "        contract = await createDirectContract(\n          { agent, tenant, signature, paymentDateObj, context },\n          transaction,\n        );")

# drop the `paymentDateObj: undefined` scrubbing from every log call
s = s.replace(
  "          logger.warn(\n            '[commission] agente sem defaultCommissionPlanId — nenhuma comissão gerada',\n            { ...context, paymentDateObj: undefined },\n          );",
  "          logger.warn(\n            '[commission] agente sem defaultCommissionPlanId — nenhuma comissão gerada',\n            { ...context },\n          );")
s = s.replace(
  "        logger.warn(\n          `[commission] contrato ${contract.status} — nenhuma comissão gerada`,\n          { ...context, paymentDateObj: undefined },\n        );",
  "        logger.warn(\n          `[commission] contrato ${contract.status} — nenhuma comissão gerada`,\n          { ...context },\n        );")
s = s.replace(
  "        logger.info('[commission] pagamento já processado nesse contrato — ignorando', {\n          ...context,\n          paymentDateObj: undefined,\n        });",
  "        logger.info('[commission] pagamento já processado nesse contrato — ignorando', {\n          ...context,\n        });")
s = s.replace(
  "          logger.info('[commission] contrato esgotado — nenhuma comissão gerada', {\n            ...context,\n            paymentDateObj: undefined,\n            totalUnits: contract.totalUnits,",
  "          logger.info('[commission] contrato esgotado — nenhuma comissão gerada', {\n            ...context,\n            totalUnits: contract.totalUnits,")
s = s.replace(
  "        logger.warn('[commission] nenhuma faixa cobre o intervalo do pagamento', {\n          ...context,\n          paymentDateObj: undefined,\n          paymentFrom,",
  "        logger.warn('[commission] nenhuma faixa cobre o intervalo do pagamento', {\n          ...context,\n          paymentFrom,")
s = s.replace(
  "      const paymentDateObj = context.paymentDateObj;\n      const referenceMonth",
  "      const referenceMonth")
s = s.replace(
  "            logger.warn('[commission] corrida no lançamento — pagamento já creditado', {\n              ...context,\n              paymentDateObj: undefined,\n            });",
  "            logger.warn('[commission] corrida no lançamento — pagamento já creditado', {\n              ...context,\n            });")
s = s.replace(
  "      logger.info('[commission] comissão lançada', {\n        ...context,\n        paymentDateObj: undefined,\n        segments: segments.length,",
  "      logger.info('[commission] comissão lançada', {\n        ...context,\n        segments: segments.length,")

open(p,'w').write(s)
print('paymentDateObj leftovers:', s.count('paymentDateObj: undefined'), '| context.paymentDateObj:', s.count('context.paymentDateObj'))
PY
node -e "require('./app/services/commissionEngine.js'); console.log('OK')"