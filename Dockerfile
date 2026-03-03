FROM node:20-alpine AS base
RUN apk add --no-cache nginx bash
WORKDIR /app

################################
# STAGE 1: Instalar dependências
# (só rebuilda se package.json mudar)
################################
FROM base AS deps

# Criar diretórios antes de copiar
RUN mkdir -p api admin master-admin white-label landing

# Copiar APENAS package.json de cada projeto
COPY api/package*.json ./api/
COPY admin/package*.json ./admin/
COPY master-admin/package*.json ./master-admin/
COPY white-label/package*.json ./white-label/
COPY landing/package*.json ./landing/

# Instalar dependências (essa layer fica em CACHE!)
RUN cd api && npm ci --omit=dev
RUN cd admin && npm ci
RUN cd master-admin && npm ci
RUN cd white-label && npm ci
RUN cd landing && npm ci

################################
# STAGE 2: Build dos projetos
# (só rebuilda o que teve código alterado)
################################
FROM base AS builder

# Copiar node_modules do stage anterior (RÁPIDO!)
COPY --from=deps /app ./

# Agora sim copiar o código fonte
COPY api ./api
COPY admin ./admin
COPY master-admin ./master-admin
COPY white-label ./white-label
COPY landing ./landing

# Build (só roda se o código mudou)
RUN cd admin && npm run build
RUN cd master-admin && npm run build
RUN cd white-label && npm run build
RUN cd landing && npm run build

################################
# STAGE 3: Imagem final (só o necessário)
################################
FROM base AS production

# Copiar node_modules de produção
COPY --from=deps /app/api/node_modules ./api/node_modules

# Copiar código da API (sem node_modules de dev)
COPY --from=builder /app/api ./api

# Copiar builds otimizados do Nuxt
COPY --from=builder /app/admin/.output ./admin/.output
COPY --from=builder /app/master-admin/.output ./master-admin/.output
COPY --from=builder /app/white-label/.output ./white-label/.output
COPY --from=builder /app/landing/.output ./landing/.output

# Configs
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY scripts/start.sh /start.sh

EXPOSE 80
CMD ["sh", "/start.sh"]