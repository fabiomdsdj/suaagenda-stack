#!/usr/bin/env bash
# Mantém admin/utils/theme.ts idêntico a white-label/utils/theme.ts.
#
# O white-label é a fonte: é ele que transforma o tema em CSS no site público.
# O admin usa a MESMA resolveTheme() no preview do editor de site. Como cada
# app tem o próprio Dockerfile (contexto = pasta do app), o arquivo precisa
# existir fisicamente nos dois; este script é o que garante que é o mesmo.
#
#   scripts/sync-theme.sh          copia white-label → admin
#   scripts/sync-theme.sh --check  só confere (sai com 1 se divergir)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/white-label/utils/theme.ts"
DST="$ROOT/admin/utils/theme.ts"

if [[ "${1:-}" == "--check" ]]; then
  if cmp -s "$SRC" "$DST"; then
    echo "theme.ts em sincronia"
  else
    echo "admin/utils/theme.ts diverge de white-label/utils/theme.ts — rode scripts/sync-theme.sh" >&2
    exit 1
  fi
  exit 0
fi

cp "$SRC" "$DST"
echo "admin/utils/theme.ts atualizado a partir de white-label/utils/theme.ts"
