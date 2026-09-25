#!/usr/bin/env bash
# Mantém admin/utils/theme.ts e landing/utils/theme.ts idênticos a
# white-label/utils/theme.ts.
#
# O white-label é a fonte: é ele que transforma o tema em CSS no site público.
# O admin usa a MESMA resolveTheme() no preview do editor de site, e a landing
# no preview dos modelos de site (components/site-preview). Como cada app tem o
# próprio Dockerfile (contexto = pasta do app), o arquivo precisa existir
# fisicamente nos três; este script é o que garante que é o mesmo.
#
#   scripts/sync-theme.sh          copia white-label → admin e landing
#   scripts/sync-theme.sh --check  só confere (sai com 1 se divergir):
#     1. admin/utils/theme.ts e landing/utils/theme.ts == white-label/utils/theme.ts;
#     2. listas de preset/fonte/raio/override da API (app/utils/websiteTheme.js)
#        == as do theme.ts — senão a API recusa (400) um id que o editor
#        oferece, ou aceita um que o site não sabe desenhar;
#     3. toda família usada em THEME_FONTS tem @fontsource importado no CSS do
#        white-label, no do admin e no do preview da landing (senão cai no
#        fallback em silêncio).
#
# A API costuma estar em outro worktree (a branch de release): API_DIR aponta
# para ele. Sem o arquivo, o passo 2 é pulado com aviso.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/white-label/utils/theme.ts"
DSTS=("$ROOT/admin/utils/theme.ts" "$ROOT/landing/utils/theme.ts")
API_THEME="${API_DIR:-$ROOT/api}/app/utils/websiteTheme.js"
WL_CSS="$ROOT/white-label/assets/css/main.css"
ADMIN_CSS="$ROOT/admin/assets/css/theme-fonts.css"
LANDING_CSS="$ROOT/landing/assets/css/site-preview.css"

if [[ "${1:-}" == "--check" ]]; then
  status=0
  for DST in "${DSTS[@]}"; do
    if cmp -s "$SRC" "$DST"; then
      echo "theme.ts em sincronia (white-label = ${DST#"$ROOT/"})"
    else
      echo "${DST#"$ROOT/"} diverge de white-label/utils/theme.ts — rode scripts/sync-theme.sh" >&2
      status=1
    fi
  done

  SRC="$SRC" API_THEME="$API_THEME" WL_CSS="$WL_CSS" ADMIN_CSS="$ADMIN_CSS" LANDING_CSS="$LANDING_CSS" node - <<'NODE' || status=1
const fs = require('fs')
const ts = fs.readFileSync(process.env.SRC, 'utf8')
let failed = false
const fail = (msg) => { console.error(msg); failed = true }

// Lê `export const NOME = [ 'a', 'b' ] as const` do theme.ts.
function tsList(name) {
  const m = ts.match(new RegExp(`export const ${name} = \\[([\\s\\S]*?)\\] as const`))
  if (!m) { fail(`theme.ts: ${name} não encontrado`); return [] }
  return [...m[1].matchAll(/'([^']+)'/g)].map((x) => x[1])
}

const lists = {
  THEME_PRESETS: tsList('THEME_PRESET_IDS'),
  THEME_FONTS: tsList('THEME_FONT_IDS'),
  THEME_RADII: tsList('THEME_RADIUS_IDS'),
  THEME_OVERRIDE_KEYS: tsList('THEME_OVERRIDE_KEYS'),
}

if (fs.existsSync(process.env.API_THEME)) {
  const api = require(process.env.API_THEME)
  for (const [name, expected] of Object.entries(lists)) {
    const got = api[name]
    if (JSON.stringify(got) !== JSON.stringify(expected)) {
      fail(`API ${name} diverge do theme.ts\n  theme.ts: ${expected.join(', ')}\n  API:      ${(got || []).join(', ')}`)
    }
  }
  if (!failed) console.log(`listas da API em sincronia (${process.env.API_THEME})`)
} else {
  console.warn(`AVISO: ${process.env.API_THEME} não existe — listas da API NÃO conferidas (defina API_DIR)`)
}

// Famílias de THEME_FONTS → pacote @fontsource (minúsculas, espaço vira hífen).
const families = new Set([...ts.matchAll(/^\s+(?:heading|body): '([^']+)',$/gm)].map((m) => m[1]))
for (const [label, file] of [['white-label', process.env.WL_CSS], ['admin', process.env.ADMIN_CSS], ['landing', process.env.LANDING_CSS]]) {
  const css = fs.readFileSync(file, 'utf8')
  const missing = [...families].filter((f) => !css.includes(`@fontsource/${f.toLowerCase().replace(/ /g, '-')}/`))
  if (missing.length) fail(`${label}: sem @fontsource para ${missing.join(', ')} (${file})`)
}
if (!failed) console.log(`fontes importadas no white-label, no admin e na landing (${families.size} famílias)`)
process.exit(failed ? 1 : 0)
NODE
  exit "$status"
fi

for DST in "${DSTS[@]}"; do
  cp "$SRC" "$DST"
  echo "${DST#"$ROOT/"} atualizado a partir de white-label/utils/theme.ts"
done
