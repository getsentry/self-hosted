#!/usr/bin/env bash
source "$(dirname $0)/_test_setup.sh"

expected_volumes="
sentry-clickhouse
sentry-data
sentry-kafka
sentry-postgres
sentry-redis
sentry-symbolicator
sentry-zookeeper
"

source create-docker-volumes.sh
source create-docker-volumes.sh
source create-docker-volumes.sh

docker_volumes=$(docker volume ls --quiet | grep '^sentry-.*')
for expected_volume in $expected_volumes; do
  [[ "$docker_volumes" =~ "$expected_volume" ]] || exit 1
done

report_success
