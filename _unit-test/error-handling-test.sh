#!/usr/bin/env bash

source _unit-test/_test_setup.sh

export REPORT_SELF_HOSTED_ISSUES=1

# This is set up in dc-detect-version.sh, but for
# our purposes we don't care about proxies.
dbuild="docker build"
source install/error-handling.sh

# mock send_envelope
send_envelope() {
  echo "Test Sending $1"
}

##########################

export -f send_envelope
echo "Testing initial send_event"
export log_file=test_log.txt
echo "Test Logs" >"$log_file"
echo "Error Msg" >>"$log_file"
breadcrumbs=$(generate_breadcrumb_json | sed '$d' | $jq -s -c)
SEND_EVENT_RESPONSE=$(
  send_event \
    "'foo' exited with status 1" \
    "Test exited with status 1" \
    "Traceback: ignore me" \
    "{\"ignore\": \"me\"}" \
    "$breadcrumbs"
)
rm "$log_file"
expected_filename='sentry-envelope-f73e4da437c42a1d28b86a81ebcff35d'
test "$SEND_EVENT_RESPONSE" == "Test Sending $expected_filename"
ENVELOPE_CONTENTS=$(cat "/tmp/$expected_filename")
test "$ENVELOPE_CONTENTS" == "$(cat _unit-test/snapshots/$expected_filename)"
echo "Pass."

##########################

echo "Testing send_event duplicate"
SEND_EVENT_RESPONSE=$(
  send_event \
    "'foo' exited with status 1" \
    "Test exited with status 1" \
    "Traceback: ignore me" \
    "{\"ignore\": \"me\"}" \
    "$breadcrumbs"
)
test "$SEND_EVENT_RESPONSE" == "Looks like you've already sent this error to us, we're on it :)"
echo "Pass."
rm "/tmp/$expected_filename"

##########################

echo "Testing cleanup without minimizing downtime"
export REPORT_SELF_HOSTED_ISSUES=0
export MINIMIZE_DOWNTIME=''
export dc=':'
echo "Test Logs" >"$log_file"
CLEANUP_RESPONSE=$(cleanup ERROR) # the linenumber of this line must match just below
rm "$log_file"
test "$CLEANUP_RESPONSE" == 'Error in _unit-test/error-handling-test.sh:62.
'\''local cmd="${BASH_COMMAND}"'\'' exited with status 0

Cleaning up...'
echo "Pass."

##########################

echo "Testing cleanup while minimizing downtime"
export REPORT_SELF_HOSTED_ISSUES=0
export MINIMIZE_DOWNTIME=1
echo "Test Logs" >"$log_file"
CLEANUP_RESPONSE=$(cleanup ERROR) # the linenumber of this line must match just below
rm "$log_file"
test "$CLEANUP_RESPONSE" == 'Error in _unit-test/error-handling-test.sh:76.
'\''local cmd="${BASH_COMMAND}"'\'' exited with status 0

*NOT* cleaning up, to clean your environment run "docker compose stop".'
echo "Pass."

##########################

report_success
