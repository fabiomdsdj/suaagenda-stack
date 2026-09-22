# ARTEFATOS HISTÓRICOS / RECOVERY — NÃO É CÓDIGO DE RUNTIME

> Nada aqui é carregado, importado ou executado pela aplicação.
> Nenhum arquivo deste diretório deve ser referenciado pelo runtime, por build ou por deploy.
> É registro forense do incidente de 22/09/2026 e da recuperação feita nos ciclos B3.25–B3.31.

Preservado no ciclo **B3.32** (22/09/2026), para que a recuperação deixasse de depender de `/tmp`.

## O incidente

Em **22/09/2026, às 13:47:46**, um revert/restore em massa reverteu 57 arquivos rastreados do
submódulo `api/`, devolvendo-os à versão pré-B3.4. Arquivos ainda não rastreados pelo Git
sobreviveram; os rastreados, não.

O trabalho dos ciclos **B3.4 / B3.5 / B3.6** (domínio de comissão) **não estava commitado no Git**,
então não havia versão de onde restaurar.

## A recuperação

Os ciclos **B3.26–B3.28** reconstruíram os arquivos perdidos a partir do **transcript do Claude Code**
(o `.jsonl` da sessão B3.4 — ver `provenance/PROVENIENCIA.md`, que registra a linha exata do
transcript de onde cada artefato saiu) e os validaram numa árvore de replay em `/tmp`, contra um
**schema MySQL descartável**, sem tocar no repositório nem no banco de desenvolvimento.

O ciclo **B3.31** promoveu 4 arquivos para o repositório, byte a byte, e a validação resultou em
**93/93 testes verdes** nas suítes focadas de comissão.

### Arquivos restaurados no `api/` pelo B3.31

| arquivo no repo | artefato aqui | SHA256 |
|---|---|---|
| `api/app/services/commissionEngine.js` | `artefatos-recuperados/commissionEngine.recuperado.js` | `a2d7502b3965c3875e5d7327dd74d2bdc8508d662533bb08b454617ed2c97720` |
| `api/app/jobs/commissionJob.js` | `artefatos-recuperados/commissionJob.recuperado.js` | `9610f2674d152a035d44236b7fd031ae7078fd4cf15addcad7f3f047e5cb220b` |
| `api/app/models/salesAgentCommission.js` | `artefatos-recuperados/salesAgentCommission.historico.js` | `c925bbe450759c852e21443850c544d061f06705fb3b3d7a4567d6e25c62bc52` |
| `api/app/models/salesAgentComissionInstallment.js` | `artefatos-recuperados/salesAgentComissionInstallment.historico.js` | `69cf8ec7466219996b81c7bbb733f59a4135d3597235830ae12d0972cc5dab30` |

No momento da preservação (B3.32) os quatro arquivos do `api/` batiam exatamente com esses hashes.

## Estrutura

| diretório | conteúdo |
|---|---|
| `artefatos-recuperados/` | os 4 arquivos recuperados, cópia byte a byte das versões validadas |
| `provenance/` | `PROVENIENCIA.md` (origem de cada artefato no transcript) e `raw_write_cmd.sh` (extração bruta) |
| `diffs/` | diffs usados na recuperação: recuperado × versão revertida, por arquivo |
| `transcript-artifacts/` | os blocos de escrita/patch extraídos do transcript (`01..06_engine*`, `11..14_job*`). `artifacts/` são os originais; `sandboxed/` são as variantes ajustadas para rodar no replay isolado |
| `replay-subset/` | recorte do domínio de comissão da árvore de replay reconstruída (services, jobs, models, controllers, routes, migrations e testes de integração) |
| `manifests/` | manifests BEFORE/AFTER/FINAL dos ciclos B3.26, B3.27 e B3.28 |
| `b3.31-backup-repo-BEFORE/` | os 4 arquivos como estavam no repo **antes** do B3.31 (versão revertida, pré-B3.4) + `git status` antes e depois |
| `logs/` | saídas de Jest dos ciclos B3.27, B3.28 e B3.31 — a evidência da validação |
| `sandbox-schema/` | DDL do schema descartável (`express_schema.sql`, 146 `CREATE TABLE`, zero `INSERT`) e o script que o recriava |
| `MANIFEST.sha256` | SHA256 dos 107 arquivos desta área (exceto ele mesmo e o `README.md`); verificar com `sha256sum -c MANIFEST.sha256` |

## Notas

- **Por que fora do submódulo `api/`:** o `.gitignore` do `api/` ignora `*.txt` e `*.log`, que é
  exatamente o formato dos manifests e dos logs de Jest. Guardá-los ali os perderia silenciosamente.
  Também ficam assim claramente separados do código de produção — nada dentro de `app/`.
- **Recorte do replay:** a árvore de replay completa (`b3.26/replay/api/`, ~17 MB) **não** foi
  preservada inteira: ela era uma cópia da árvore de trabalho e incluía `api/tmp/backup-2026-07-05*.sql`,
  um dump de banco de 9 MB. Preservamos apenas o recorte do domínio de comissão, sem dumps e sem `.env`.
- `sandbox-schema/recreate_test_schema.sh` contém as credenciais **locais de docker de desenvolvimento**
  (`root`/`example`, as mesmas do `docker-compose`). Não são credenciais de produção.
- A proveniência original aponta para o transcript
  `~/.claude/projects/-home-fabiomdsdj-Documents-sistema-suaagenda-stack/ab39b7d8-55a9-4ff5-83c2-79fefea48c99.jsonl`,
  que é um arquivo local fora deste repositório e **não** foi copiado para cá.
- Este ciclo (B3.32) foi **somente de preservação**: nenhum código de runtime, migration, teste,
  configuração ou banco foi alterado.
