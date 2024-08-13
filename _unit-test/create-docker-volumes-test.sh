#!/usr/bin/env bash

source _unit-test/_test_setup.sh

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
sentry-symbolicator"

before=$(get_volumes)

test "$before" == "" || test "$before" == "$expected_volumes"

source install/create-docker-volumes.sh

after=$(get_volumes)
test "$after" == "$expected_volumes"

report_success
