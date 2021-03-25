#!/usr/bin/env bash
source _test_setup.sh

cfg="relay/config.yml"
creds="relay/credentials.json"

# Relay files don't exist in a clean clone.
test ! -f $cfg
test ! -f $creds

# Running the install script adds them.
./install/relay-credentials.sh
test -f $cfg
test -f $creds
test "$(jq -r 'keys[2]' $creds)" = "secret_key"

# If the files exist we don't touch it.
echo GARBAGE > $cfg
echo MOAR GARBAGE > $creds
./install/relay-credentials.sh
test "$(cat $cfg)" = "GARBAGE"
test "$(cat $creds)" = "MOAR GARBAGE"

echo "Pass"
