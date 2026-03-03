#!/bin/bash
set -e

echo "🗓️  DEPLOYING SUAAGENDA STACK"
echo "==============================="
echo ""

# Verificar conta
echo "📋 Conta Fly.io:"
flyctl auth whoami
echo ""

# Verificar app
echo "📦 App: suaagenda-stack"
echo "🌍 Região: gru (São Paulo)"
echo ""

read -p "✅ Continuar com deploy? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deploy cancelado"
    exit 1
fi

echo ""
echo "🚀 Iniciando deploy..."
flyctl deploy --local-only

echo ""
echo "✅ Deploy concluído!"
echo ""
echo "🔗 URLs disponíveis:"
echo "   📡 API:          https://api.suaagenda.link"
echo "   🎛️  Admin:        https://admin.suaagenda.link"
echo "   🛠️  Master:       https://master.suaagenda.link"
echo "   🏷️  White Label:  https://app.suaagenda.link"
echo "   📰 Landing:      https://landing.suaagenda.com"
echo ""
echo "📊 Ver logs:     flyctl logs"
echo "📈 Status:       flyctl status"