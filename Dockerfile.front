# ---------- Build ----------
    FROM node:20-alpine AS builder

    WORKDIR /app
    COPY package*.json ./
    RUN npm install
    
    COPY . .
    RUN npm run build
    
    # ---------- Run ----------
    FROM node:20-alpine
    
    WORKDIR /app
    COPY --from=builder /app/.output ./.output
    
    ENV NODE_ENV=production
    EXPOSE 3000
    
    CMD ["node", ".output/server/index.mjs"]