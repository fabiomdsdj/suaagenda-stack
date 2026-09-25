#!/usr/bin/env bash
# Mantém api/app/data/siteModelSeeds.json igual à base inicial gerada dos
# modelos de site da landing (landing/data/siteModels → utils/siteModelSeed.ts).
#
# A landing é a fonte: é lá que os modelos são escritos e mostrados no
# catálogo /site-para-<segmento>. A API usa a cópia no cadastro para iniciar o
# site do cliente com o tema e os textos do modelo escolhido (siteModel).
# Como cada app tem o próprio Dockerfile, o arquivo precisa existir na API;
# este script é o que garante que é o mesmo.
#
#   scripts/sync-site-models.sh          gera e grava na API
#   scripts/sync-site-models.sh --check  só confere (sai com 1 se divergir)
#
# A API costuma estar em outro worktree (a branch de release): API_DIR aponta
# para ele (igual ao sync-theme.sh).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LANDING="$ROOT/landing"
DST="${API_DIR:-$ROOT/api}/app/data/siteModelSeeds.json"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
(cd "$LANDING" && node --experimental-strip-types --no-warnings scripts/export-site-model-seeds.mjs "$TMP")

if [[ "${1:-}" == "--check" ]]; then
  if [[ -f "$DST" ]] && cmp -s "$TMP" "$DST"; then
    echo "siteModelSeeds.json em sincronia ($DST)"
    exit 0
  fi
  echo "$DST diverge dos modelos da landing — rode scripts/sync-site-models.sh" >&2
  exit 1
fi

mkdir -p "$(dirname "$DST")"
cp "$TMP" "$DST"
echo "siteModelSeeds.json gravado em $DST"
