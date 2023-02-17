#!/usr/bin/env bash

source _unit-test/_test_setup.sh
source install/dc-detect-version.sh

# using _file format for these variables since there is a creds defined in dc-detect-version.sh
cfg_file=relay/config.yml
creds_file=relay/credentials.json

# Relay files don't exist in a clean clone.
test ! -f $cfg_file
test ! -f $creds_file

# Running the install script adds them.
source install/ensure-relay-credentials.sh
test -f $cfg_file
test -f $creds_file
test "$(jq -r 'keys[2]' "$creds_file")" = "secret_key"

# If the files exist we don't touch it.
echo GARBAGE >$cfg_file
echo MOAR GARBAGE >$creds_file
source install/ensure-relay-credentials.sh
test "$(cat $cfg_file)" = "GARBAGE"
test "$(cat $creds_file)" = "MOAR GARBAGE"

report_success
