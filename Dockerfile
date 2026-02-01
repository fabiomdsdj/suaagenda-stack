FROM node:20-alpine

RUN apk add --no-cache nginx bash

WORKDIR /app

COPY api ./api
COPY admin ./admin
COPY master-admin ./master-admin
COPY white-label ./white-label
COPY landing ./landing

# API
RUN cd api && npm install

# Nuxt builds
RUN cd admin && npm install && npm run build
RUN cd master-admin && npm install && npm run build
RUN cd white-label && npm install && npm run build
RUN cd landing && npm install && npm run build

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY scripts/start.sh /start.sh

EXPOSE 80

CMD ["sh", "/start.sh"]
