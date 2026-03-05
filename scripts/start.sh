#!/bin/sh
set -e

echo "🚀 Iniciando SuaAgenda Stack..."

################################
# API (Node via start-all.js)
################################
echo "🧠 Iniciando API + Workers BullMQ..."
node --max-old-space-size=384 /app/start-all.js &

################################
# Nuxt Admin
################################
echo "🎛️ Nuxt Admin (3001)"
PORT=3001 NUXT_PUBLIC_APP=admin node /app/admin/.output/server/index.mjs &

################################
# Nuxt Master Admin
################################
echo "🛠️ Nuxt Master Admin (3002)"
PORT=3002 NUXT_PUBLIC_APP=master node /app/master-admin/.output/server/index.mjs &

################################
# Nuxt White Label
################################
echo "🏷️ Nuxt White Label (3003)"
PORT=3003 NUXT_PUBLIC_APP=white node /app/white-label/.output/server/index.mjs &

################################
# Aguarda serviços subirem
################################
echo "⏳ Aguardando serviços..."
sleep 5

################################
# Nginx (porta 80) — mantém processo vivo
################################
echo "🌐 Nginx na porta 80"
nginx -g "daemon off;"