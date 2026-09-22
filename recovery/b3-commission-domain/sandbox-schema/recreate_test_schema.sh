#!/usr/bin/env bash
# Recria o schema descartavel usado no B3.26 (estrutura de `express` + tabela `plans`).
# Nao toca no schema `express`.
set -e
D=$(dirname "$0")
docker exec db_beleza mysql -uroot -pexample -e \
  "DROP DATABASE IF EXISTS express_b326_replay; CREATE DATABASE express_b326_replay CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
docker exec -i db_beleza mysql -uroot -pexample express_b326_replay < "$D/express_schema.sql"
docker exec db_beleza sh -c 'mysqldump -uroot -pexample --no-create-info --set-gtid-purged=OFF express plans' \
  | docker exec -i db_beleza mysql -uroot -pexample express_b326_replay
echo "express_b326_replay recriado."
