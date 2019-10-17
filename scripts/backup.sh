#!/bin/bash
set -o allexport
source .env
set +o allexport
docker-compose exec postgres pg_dump sentry | gzip > ./backup/dump_`date +%d-%m-%Y"_"%H_%M_%S`.sql.gz
