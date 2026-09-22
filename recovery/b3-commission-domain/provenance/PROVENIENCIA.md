# B3.27 — proveniência dos artefatos recuperados

Fonte única: transcript do Claude Code
`~/.claude/projects/-home-fabiomdsdj-Documents-sistema-suaagenda-stack/ab39b7d8-55a9-4ff5-83c2-79fefea48c99.jsonl`
Sessão = ciclo **B3.4** (prompt inicial: "CONTEXTO — B3.4 / IMPLEMENTAÇÃO DO MODELO DE COMISSÃO"), cwd `.../suaagenda-stack/api`.

| artefato | linha do jsonl | timestamp | estado hoje no api/ |
|---|---|---|---|
| database/migrations/20260922100000-create-commission_plans-table.js | 129 | 15:0x | IDÊNTICO |
| database/migrations/20260922100100-create-commission_plan_tiers-table.js | 130 | 15:0x | IDÊNTICO |
| database/migrations/20260922100200-add-relationship-commission_plans-to-sales_agents-table.js | 140 | 15:0x | IDÊNTICO |
| database/migrations/20260922100400-create-sales_agent_commission_terms-table.js | 141 | 15:0x | IDÊNTICO |
| database/migrations/20260922100300-add-commission-plan-fields-to-sales_agent_commissions-table.js | 146 | 15:0x | IDÊNTICO |
| database/migrations/20260922100500-...-installments-table.js | 154 | 15:0x | IDÊNTICO |
| app/models/commissionPlan.js | 185 | 15:0x | IDÊNTICO |
| app/models/commissionPlanTier.js | 185 | 15:0x | IDÊNTICO |
| app/models/salesAgentCommissionTerm.js | 185 | 15:0x | IDÊNTICO |
| **app/models/salesAgentCommission.js** | **197** | **15:06:35Z** | **PERDIDO** (arquivo no api/ é a versão pré-B3.4) |
| **app/models/salesAgentComissionInstallment.js** | **200** | **15:06:54Z** | **PERDIDO** (arquivo no api/ é a versão pré-B3.4) |
| __tests__/integration/salesAgentCommissionSchema.test.js | 213 | 15:0x | DIVERGE (provável edição legítima posterior) |
| __tests__/utils/sequelizeModels.js | 257 | 15:0x | IDÊNTICO |

Os dois artefatos perdidos são **escritas consecutivas** (19 s de intervalo).
`app/models/salesAgent.js` NÃO é um artefato perdido: em runtime o model já expõe
`pixKey` e `defaultCommissionPlanId` (verificado via rawAttributes). Não há nada a recuperar nele.
