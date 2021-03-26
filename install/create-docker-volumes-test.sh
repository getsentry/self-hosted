#!/usr/bin/env bash
source "$(dirname $0)/_test_setup.sh"

expected=7
count() {
  docker volume ls --quiet | grep '^sentry-.*' | wc -l
}

# Maybe they exist prior, maybe they don't. Script is idempotent.

before=$(count)
test $before -eq 0 || test $before -eq $expected

source create-docker-volumes.sh
source create-docker-volumes.sh
source create-docker-volumes.sh

test $(count) -eq $expected

report_success
