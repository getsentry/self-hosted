#!/bin/bash
set -o allexport
source .env
set +o allexport
cat $1 |  docker-compose exec  -T postgres sh -c "psql -U $DB_USER -d $DB_PASSWORD $MYSQL_DATABASE -1 -f $1"
