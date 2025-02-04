#!/usr/bin/env bash

# This is a test file for a part of `_lib.sh`, where we read `.env.custom` file if there is one.
# We only want to give very minimal value to the `.env.custom` file, and expect that it would
# be merged with the original `.env` file, with the `.env.custom` file taking precedence.
cat <<EOF > .env.custom
SENTRY_EVENT_RETENTION_DAYS=10
EOF

# The `_test_setup.sh` script sources `install/_lib.sh`, so.. finger crossed this should works.
source _unit-test/_test_setup.sh

test "$SENTRY_EVENT_RETENTION_DAYS" == "10"
echo "Pass"
test "$SENTRY_BIND" == "9000"
echo "Pass"
test "$COMPOSE_PROJECT_NAME" == "sentry-self-hosted"
echo "Pass"

rm .env.custom

report_success
