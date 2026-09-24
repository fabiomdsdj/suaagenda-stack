#!/usr/bin/env bash
# Mantém admin/utils/whatsapp.ts idêntico a white-label/utils/whatsapp.ts.
#
# O white-label é a fonte: é ele que monta os links wa.me do site público.
# O admin usa a MESMA validação/máscara no campo "WhatsApp para contato". Como cada
# app tem o próprio Dockerfile (contexto = pasta do app), o arquivo precisa
# existir fisicamente nos dois; este script é o que garante que é o mesmo.
#
#   scripts/sync-whatsapp.sh          copia white-label → admin
#   scripts/sync-whatsapp.sh --check  só confere (sai com 1 se divergir)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/white-label/utils/whatsapp.ts"
DST="$ROOT/admin/utils/whatsapp.ts"

if [[ "${1:-}" == "--check" ]]; then
  if cmp -s "$SRC" "$DST"; then
    echo "whatsapp.ts em sincronia"
  else
    echo "admin/utils/whatsapp.ts diverge de white-label/utils/whatsapp.ts — rode scripts/sync-whatsapp.sh" >&2
    exit 1
  fi
  exit 0
fi

cp "$SRC" "$DST"
echo "admin/utils/whatsapp.ts atualizado a partir de white-label/utils/whatsapp.ts"
