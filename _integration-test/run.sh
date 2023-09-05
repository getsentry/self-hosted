#!/usr/bin/env bash
set -ex

source install/_lib.sh
source install/dc-detect-version.sh

echo "${_group}Setting up variables and helpers ..."
export SENTRY_TEST_HOST="${SENTRY_TEST_HOST:-http://localhost:9000}"
TEST_USER='test@example.com'
TEST_PASS='test123TEST'
COOKIE_FILE=$(mktemp)

# Courtesy of https://stackoverflow.com/a/2183063/90297
trap_with_arg() {
  func="$1"
  shift
  for sig; do
    trap "$func $sig "'$LINENO' "$sig"
  done
}

DID_TEAR_DOWN=0
# the teardown function will be the exit point
teardown() {
  if [ "$DID_TEAR_DOWN" -eq 1 ]; then
    return 0
  fi
  DID_TEAR_DOWN=1

  if [ "$1" != "EXIT" ]; then
    echo "An error occurred, caught SIG$1 on line $2"
  fi

  echo "Tearing down ..."
  rm $COOKIE_FILE
  echo "Done."
}
trap_with_arg teardown ERR INT TERM EXIT
echo "${_endgroup}"

echo "${_group}Starting Sentry for tests ..."
# Disable beacon for e2e tests
echo 'SENTRY_BEACON=False' >>$SENTRY_CONFIG_PY
echo y | $dcr web createuser --force-update --superuser --email $TEST_USER --password $TEST_PASS
$dc up -d
printf "Waiting for Sentry to be up"
timeout 90 bash -c 'until $(curl -Isf -o /dev/null $SENTRY_TEST_HOST); do printf '.'; sleep 0.5; done'
echo ""
echo "${_endgroup}"

echo "${_group}Running tests ..."
get_csrf_token() { awk '$6 == "sc" { print $7 }' $COOKIE_FILE; }
sentry_api_request() { curl -s -H 'Accept: application/json; charset=utf-8' -H "Referer: $SENTRY_TEST_HOST" -H 'Content-Type: application/json' -H "X-CSRFToken: $(get_csrf_token)" -b "$COOKIE_FILE" -c "$COOKIE_FILE" "$SENTRY_TEST_HOST/api/0/$1" ${@:2}; }

login() {
  INITIAL_AUTH_REDIRECT=$(curl -sL -o /dev/null $SENTRY_TEST_HOST -w %{url_effective})
  if [ "$INITIAL_AUTH_REDIRECT" != "$SENTRY_TEST_HOST/auth/login/sentry/" ]; then
    echo "Initial /auth/login/ redirect failed, exiting..."
    echo "$INITIAL_AUTH_REDIRECT"
    exit 1
  fi

  CSRF_TOKEN_FOR_LOGIN=$(curl $SENTRY_TEST_HOST -sL -c "$COOKIE_FILE" | awk -F "['\"]" '
    /csrfmiddlewaretoken/ {
    print $4 "=" $6;
    exit;
  }')

  curl -sL --data-urlencode 'op=login' --data-urlencode "username=$TEST_USER" --data-urlencode "password=$TEST_PASS" --data-urlencode "$CSRF_TOKEN_FOR_LOGIN" "$SENTRY_TEST_HOST/auth/login/sentry/" -H "Referer: $SENTRY_TEST_HOST/auth/login/sentry/" -b "$COOKIE_FILE" -c "$COOKIE_FILE"
}

LOGIN_RESPONSE=$(login)
declare -a LOGIN_TEST_STRINGS=(
  '"isAuthenticated":true'
  '"username":"test@example.com"'
  '"isSuperuser":true'
)
for i in "${LOGIN_TEST_STRINGS[@]}"; do
  echo "Testing '$i'..."
  echo "$LOGIN_RESPONSE" | grep "${i}[,}]" >&/dev/null
  echo "Pass."
done
echo "${_endgroup}"

echo "${_group}Running moar tests !!!"
# Set up initial/required settings (InstallWizard request)
export -f sentry_api_request get_csrf_token
sentry_api_request "internal/options/?query=is:required" -X PUT --data '{"mail.use-tls":false,"mail.username":"","mail.port":25,"system.admin-email":"ben@byk.im","mail.password":"","system.url-prefix":"'"$SENTRY_TEST_HOST"'","auth.allow-registration":false,"beacon.anonymous":true}' >/dev/null

# Hacky way to get around test flakiness for now
sleep 60
# We ignore the protocol and the host as we already know those
SENTRY_DSN=$(sentry_api_request "projects/sentry/internal/keys/" | awk 'BEGIN { RS=",|:{\n"; FS="\""; } $2 == "public" && $4 ~ "^http" { print $4; exit; }')
DSN_PIECES=($(echo $SENTRY_DSN | sed -ne 's|^https\{0,1\}://\([0-9a-z]\{1,\}\)@[^/]\{1,\}/\([0-9]\{1,\}\)$|\1 \2|p' | tr ' ' '\n'))
SENTRY_KEY=${DSN_PIECES[0]}
PROJECT_ID=${DSN_PIECES[1]}

TEST_EVENT_ID=$(
  export LC_ALL=C
  head /dev/urandom | tr -dc "a-f0-9" | head -c 32
)
# Thanks @untitaker - https://forum.sentry.io/t/how-can-i-post-with-curl-a-sentry-event-which-authentication-credentials/4759/2?u=byk
echo "Creating test event..."
curl -sf --data '{"event_id": "'"$TEST_EVENT_ID"'","level":"error","message":"a failure","extra":{"object":"42"}}' -H 'Content-Type: application/json' -H "X-Sentry-Auth: Sentry sentry_version=7, sentry_key=$SENTRY_KEY, sentry_client=test-bash/0.1" "$SENTRY_TEST_HOST/api/$PROJECT_ID/store/" -o /dev/null

EVENT_PATH="projects/sentry/internal/events/$TEST_EVENT_ID/"
export SENTRY_TEST_HOST COOKIE_FILE EVENT_PATH
printf "Getting the test event back"
timeout 60 bash -c 'until $(sentry_api_request "$EVENT_PATH" -Isf -X GET -o /dev/null); do printf '.'; sleep 0.5; done'
echo " got it!"

EVENT_RESPONSE=$(sentry_api_request "$EVENT_PATH")
declare -a EVENT_TEST_STRINGS=(
  '"eventID":"'"$TEST_EVENT_ID"'"'
  '"message":"a failure"'
  '"title":"a failure"'
  '"object":"42"'
)
for i in "${EVENT_TEST_STRINGS[@]}"; do
  echo "Testing '$i'..."
  echo "$EVENT_RESPONSE" | grep "${i}[,}]" >&/dev/null
  echo "Pass."
done
echo "${_endgroup}"

echo "${_group}Ensure cleanup crons are working ..."
$dc ps -a | tee debug.log | grep -E -e '\-cleanup\s+running\s+' -e '\-cleanup[_-].+\s+Up\s+'
# to debug https://github.com/getsentry/self-hosted/issues/1171
echo '------------------------------------------'
cat debug.log
echo '------------------------------------------'
echo "${_endgroup}"

echo "${_group}Test custom CAs work ..."
source _integration-test/custom-ca-roots/setup.sh
$dcr --no-deps web python3 /etc/sentry/test-custom-ca-roots.py
source _integration-test/custom-ca-roots/teardown.sh
echo "${_endgroup}"

echo "${_group}Test that profiling work ..."
echo "Sending a test profile..."
PROFILE_FIXTURE_PATH="$(git rev-parse --show-toplevel)/_integration-test/fixtures/envelope-with-profile"
curl -sf --data-binary @$PROFILE_FIXTURE_PATH -H 'Content-Type: application/x-sentry-envelope' -H "X-Sentry-Auth: Sentry sentry_version=7, sentry_key=$SENTRY_KEY, sentry_client=test-bash/0.1" "$SENTRY_TEST_HOST/api/$PROJECT_ID/envelope/" -o /dev/null

printf "Getting the test profile back"
PROFILE_ID="$(jq -r -n --slurpfile profile $PROFILE_FIXTURE_PATH '$profile[4].event_id')"
PROFILE_PATH="api/0/projects/sentry/sentry/profiling/raw_profiles/$PROFILE_ID/"
timeout 60 bash -c 'until $(sentry_api_request "$PROFILE_PATH" -Isf -X GET -o /dev/null); do printf '.'; sleep 0.5; done'
echo " got it!"
echo "${_endgroup}"

# Table formatting based on https://stackoverflow.com/a/39144364
COMPOSE_PS_OUTPUT=$(docker compose ps --format json | jq -r \
  '.[] |
   # we only care about running services. geoipupdate and fixture-custom-ca-roots always exits, so we ignore it
   select(.State != "running" and .Service != "geoipupdate" and .Service != "fixture-custom-ca-roots") |
   # Filter to only show the service name and state
   with_entries(select(.key | in({"Service":1, "State":1})))
 ')

if [[ "$COMPOSE_PS_OUTPUT" ]]; then
  echo "Services failed, oh no!"
  echo "$COMPOSE_PS_OUTPUT" | jq -rs '["Service","State"], ["-------","-----"], (.[]|[.Service, .State]) | @tsv'
  exit 1
fi
