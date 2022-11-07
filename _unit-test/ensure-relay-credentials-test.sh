#!/usr/bin/env bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/_test_setup.sh"

source "$PROJECT_ROOT/install/dc-detect-version.sh"

# using _file format for these variables since there is a creds defined in dc-detect-version.sh
cfg_file="$PROJECT_ROOT/relay/config.yml"
creds_file="$PROJECT_ROOT/relay/credentials.json"

# Relay files don't exist in a clean clone.
test ! -f $cfg_file
test ! -f $creds_file

# Running the install script adds them.
source "$PROJECT_ROOT/install/ensure-relay-credentials.sh"
test -f $cfg_file
test -f $creds_file
test "$(jq -r 'keys[2]' $creds_file)" = "secret_key"

# If the files exist we don't touch it.
echo GARBAGE >$cfg_file
echo MOAR GARBAGE >$creds_file
source "$PROJECT_ROOT/install/ensure-relay-credentials.sh"
test "$(cat $cfg_file)" = "GARBAGE"
test "$(cat $creds_file)" = "MOAR GARBAGE"

report_success
