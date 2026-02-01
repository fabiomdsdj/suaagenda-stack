#!/bin/sh
set -e

echo "🚀 Iniciando serviços..."

################################
# API (Node)
################################
echo "🧠 API Node (3010)"
PORT=3010 node api/server.js &

################################
# Nuxt Admin
################################
echo "🎛️ Nuxt Admin (3001)"
cd admin
PORT=3001 \
NUXT_PUBLIC_APP=admin \
node .output/server/index.mjs &
cd ..

################################
# Nuxt Master Admin
################################
echo "🛠️ Nuxt Master Admin (3002)"
cd master-admin
PORT=3002 \
NUXT_PUBLIC_APP=master \
node .output/server/index.mjs &
cd ..

################################
# Nuxt White Label
################################
echo "🏷️ Nuxt White Label (3003)"
cd white-label
PORT=3003 \
NUXT_PUBLIC_APP=white \
node .output/server/index.mjs &
cd ..

################################
# Nuxt Landing
################################
echo "📰 Nuxt Landing (3004)"
cd landing
PORT=3004 \
NUXT_PUBLIC_APP=landing \
node .output/server/index.mjs &
cd ..

################################
# Nginx (porta 80)
################################
echo "🌐 Nginx"
nginx -g "daemon off;"
