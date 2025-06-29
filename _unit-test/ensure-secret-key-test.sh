#!/usr/bin/env bash

source _unit-test/_test_setup.sh
source install/dc-detect-version.sh

source install/ensure-files-from-examples.sh
source install/generate-secret-key.sh

grep -q "SENTRY_SYSTEM_SECRET_KEY=" .env.custom
status=$?
test "0" == "$status"
echo "Pass"
report_success
