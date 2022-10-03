#!/usr/bin/env bash
source "$(dirname $0)/_test_setup.sh"

export REPORT_SELF_HOSTED_ISSUES=1

source error-handling.sh

# mock send_envelope
send_envelope() {
  echo "Test Sending $1"
}

export -f send_envelope
echo "Testing initial send_event"
export log_file="test_log.txt"
echo "Test Logs" > "$basedir/$log_file"
SEND_EVENT_RESPONSE=$(send_event "12345123451234512345123451234512" "Test exited with status 1")
rm "$basedir/$log_file"
test "$SEND_EVENT_RESPONSE" == 'Test Sending sentry-envelope-12345123451234512345123451234512'
ENVELOPE_CONTENTS=$(cat /tmp/sentry-envelope-12345123451234512345123451234512)
test "$ENVELOPE_CONTENTS" == "$(cat "$basedir/_unit-test/snapshots/sentry-envelope-12345123451234512345123451234512")"
echo "Pass."

echo "Testing send_event duplicate"
SEND_EVENT_RESPONSE=$(send_event "12345123451234512345123451234512" "Test exited with status 1")
test "$SEND_EVENT_RESPONSE" == "Looks like you've already sent this error to us, we're on it :)"
echo "Pass."
rm '/tmp/sentry-envelope-12345123451234512345123451234512'

echo "Testing cleanup without minimizing downtime"
export REPORT_SELF_HOSTED_ISSUES=0
export MINIMIZE_DOWNTIME=''
export dc=':'
CLEANUP_RESPONSE=$(cleanup ERROR)
test "$CLEANUP_RESPONSE" == 'Error in ./_unit-test/error-handling-test.sh:34.
'\''local cmd="${BASH_COMMAND}"'\'' exited with status 0

Cleaning up...'
echo "Pass."

echo "Testing cleanup while minimizing downtime"
export REPORT_SELF_HOSTED_ISSUES=0
export MINIMIZE_DOWNTIME=1
CLEANUP_RESPONSE=$(cleanup ERROR)
test "$CLEANUP_RESPONSE" == 'Error in ./_unit-test/error-handling-test.sh:44.
'\''local cmd="${BASH_COMMAND}"'\'' exited with status 0

*NOT* cleaning up, to clean your environment run "docker compose stop".'
echo "Pass."

report_success
