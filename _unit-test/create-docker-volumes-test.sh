#!/usr/bin/env bash
source "$(dirname $0)/_test_setup.sh"

get_volumes() {
  # If grep returns no strings, we still want to return without error
  docker volume ls --quiet | { grep '^sentry-.*' || true; } | sort
}

# Maybe they exist prior, maybe they don't. Script is idempotent.

expected_volumes="sentry-clickhouse
sentry-data
sentry-kafka
sentry-postgres
sentry-redis
sentry-symbolicator
sentry-zookeeper"

before=$(get_volumes)

test "$before" == "" || test "$before" == "$expected_volumes"

source create-docker-volumes.sh
source create-docker-volumes.sh
source create-docker-volumes.sh

after=$(get_volumes)
test "$after" == "$expected_volumes"

report_success
