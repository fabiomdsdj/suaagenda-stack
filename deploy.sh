#!/bin/bash
set -e

# ── Cores ──────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# ── Apps mapeados ──────────────────────────────────────
APPS=(
  "suaagenda-api|📡 API|https://api.suaagenda.link"
  "suaagenda-admin|🎛️  Admin|https://admin.suaagenda.link"
  "suaagenda-master|🛠️  Master|https://master.suaagenda.link"
  #"suaagenda-wl|🏷️  White Label|https://app.suaagenda.link"
  "suaagenda-landing|📰 Landing|https://landing.suaagenda.com"
  "suaagenda-worker|⚙️  Workers|N/A"
)

echo ""
echo -e "${BOLD}🗓️  DEPLOY — SUAAGENDA STACK${RESET}"
echo "════════════════════════════════════"
echo ""
echo -e "${CYAN}📋 Conta Fly.io:${RESET}"
flyctl auth whoami
echo ""

# ── Seleção do app ─────────────────────────────────────
echo -e "${BOLD}Qual app deseja deployar?${RESET}"
echo ""
echo "  0) 🚀 TODOS (deploy completo)"
echo ""
i=1
for entry in "${APPS[@]}"; do
  IFS='|' read -r app label url <<< "$entry"
  echo "  $i) $label  ${CYAN}(-a $app)${RESET}"
  ((i++))
done

echo ""
read -p "👉 Escolha [0-$((${#APPS[@]}))]: " choice
echo ""

# ── Confirma ───────────────────────────────────────────
if [ "$choice" = "0" ]; then
  echo -e "${YELLOW}⚠️  Deploy de TODOS os apps${RESET}"
else
  idx=$((choice - 1))
  IFS='|' read -r selected_app selected_label selected_url <<< "${APPS[$idx]}"
  echo -e "📦 App selecionado: ${BOLD}$selected_label${RESET}  ${CYAN}(-a $selected_app)${RESET}"
fi

echo ""
read -p "✅ Confirmar deploy? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${RED}❌ Deploy cancelado${RESET}"
  exit 1
fi

# ── Deploy ─────────────────────────────────────────────
echo ""
echo -e "${YELLOW}🚀 Iniciando deploy...${RESET}"
echo ""

deploy_app() {
  local app=$1 label=$2 url=$3
  echo -e "${CYAN}▶ Deployando $label  (-a $app)...${RESET}"
  flyctl deploy --local-only -a "$app"
  echo -e "${GREEN}✅ $label concluído${RESET}"
  echo ""
}

if [ "$choice" = "0" ]; then
  for entry in "${APPS[@]}"; do
    IFS='|' read -r app label url <<< "$entry"
    deploy_app "$app" "$label" "$url"
  done
else
  deploy_app "$selected_app" "$selected_label" "$selected_url"
fi

# ── Sumário ────────────────────────────────────────────
echo "════════════════════════════════════"
echo -e "${GREEN}${BOLD}✅ Deploy concluído!${RESET}"
echo ""
echo -e "${BOLD}🔗 URLs:${RESET}"
for entry in "${APPS[@]}"; do
  IFS='|' read -r app label url <<< "$entry"
  [ "$url" != "N/A" ] && echo "   $label → $url"
done

echo ""
echo -e "${BOLD}🛠️  Comandos úteis:${RESET}"
echo ""
echo -e "  ${CYAN}Logs em tempo real:${RESET}"
for entry in "${APPS[@]}"; do
  IFS='|' read -r app label url <<< "$entry"
  echo "   $label → flyctl logs -a $app"
done
echo ""
echo -e "  ${CYAN}Status:${RESET}"
for entry in "${APPS[@]}"; do
  IFS='|' read -r app label url <<< "$entry"
  echo "   $label → flyctl status -a $app"
done
echo ""
echo -e "  ${CYAN}SSH na máquina:${RESET}"
for entry in "${APPS[@]}"; do
  IFS='|' read -r app label url <<< "$entry"
  echo "   $label → flyctl ssh console -a $app"
done
echo ""