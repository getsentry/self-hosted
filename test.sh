#!/usr/bin/env bash
set -e

export SENTRY_TEST_HOST="${SENTRY_TEST_HOST:-http://localhost:9000}"
TEST_USER='test@example.com'
TEST_PASS='test123TEST'
COOKIE_FILE=$(mktemp)

# Courtesy of https://stackoverflow.com/a/2183063/90297
trap_with_arg() {
  func="$1" ; shift
  for sig ; do
    trap "$func $sig "'$LINENO' "$sig"
  done
}

DID_CLEAN_UP=0
# the cleanup function will be the exit point
cleanup () {
  if [ "$DID_CLEAN_UP" -eq 1 ]; then
    return 0;
  fi
  DID_CLEAN_UP=1

  if [ "$1" != "EXIT" ]; then
    echo "An error occurred, caught SIG$1 on line $2";
  fi

  echo "Cleaning up..."
  rm $COOKIE_FILE
  echo "Done."
}
trap_with_arg cleanup ERR INT TERM EXIT

# Disable beacon for e2e tests
echo 'SENTRY_BEACON=False' >> sentry/sentry.conf.py
docker-compose run --rm web createuser --superuser --email $TEST_USER --password $TEST_PASS || true
docker-compose up -d
printf "Waiting for Sentry to be up"; timeout 60 bash -c 'until $(curl -Isf -o /dev/null $SENTRY_TEST_HOST); do printf '.'; sleep 0.5; done'

get_csrf_token () { awk '$6 == "sc" { print $7 }' $COOKIE_FILE; }
sentry_api_request () { curl -s -H 'Accept: application/json; charset=utf-8' -H "Referer: $SENTRY_TEST_HOST" -H 'Content-Type: application/json' -H "X-CSRFToken: $(get_csrf_token)" -b "$COOKIE_FILE" -c "$COOKIE_FILE" "$SENTRY_TEST_HOST/api/0/$1" ${@:2}; }

login () {
  INITIAL_AUTH_REDIRECT=$(curl -sL -o /dev/null $SENTRY_TEST_HOST -w %{url_effective})
  if [ "$INITIAL_AUTH_REDIRECT" != "$SENTRY_TEST_HOST/auth/login/sentry/" ]; then
    echo "Initial /auth/login/ redirect failed, exiting..."
    echo "$INITIAL_AUTH_REDIRECT"
    exit -1
  fi

  CSRF_TOKEN_FOR_LOGIN=$(curl $SENTRY_TEST_HOST -sL -c "$COOKIE_FILE" | awk -F "'" '
    /csrfmiddlewaretoken/ {
    print $4 "=" $6;
    exit;
  }')

  curl -sL --data-urlencode 'op=login' --data-urlencode "username=$TEST_USER" --data-urlencode "password=$TEST_PASS" --data-urlencode "$CSRF_TOKEN_FOR_LOGIN" "$SENTRY_TEST_HOST/auth/login/sentry/" -H "Referer: $SENTRY_TEST_HOST/auth/login/sentry/" -b "$COOKIE_FILE" -c "$COOKIE_FILE";
}

LOGIN_RESPONSE=$(login);
declare -a LOGIN_TEST_STRINGS=(
  '"isAuthenticated":true'
  '"username":"test@example.com"'
  '"isSuperuser":true'
)
for i in "${LOGIN_TEST_STRINGS[@]}"
do
  echo "Testing '$i'..."
  echo "$LOGIN_RESPONSE" | grep "$i[,}]" >& /dev/null
  echo "Pass."
done

# Set up initial/required settings (InstallWizard request)
sentry_api_request "internal/options/?query=is:required" -X PUT --data '{"mail.use-tls":false,"mail.username":"","mail.port":25,"system.admin-email":"ben@byk.im","mail.password":"","mail.from":"root@localhost","system.url-prefix":"'"$SENTRY_TEST_HOST"'","auth.allow-registration":false,"beacon.anonymous":true}' > /dev/null

SENTRY_DSN=$(sentry_api_request "projects/sentry/internal/keys/" | awk 'BEGIN { RS=",|:{\n"; FS="\""; } $2 == "public" && $4 ~ "^http" { print $4; exit; }')
# We ignore the protocol and the host as we already know those
DSN_PIECES=(`echo $SENTRY_DSN | sed -ne 's|^https\?://\([0-9a-z]\+\)@[^/]\+/\([0-9]\+\)$|\1\n\2|p'`)
SENTRY_KEY=${DSN_PIECES[0]}
PROJECT_ID=${DSN_PIECES[1]}

TEST_EVENT_ID=$(export LC_ALL=C; head /dev/urandom | tr -dc "a-f0-9" | head -c 32)
# Thanks @untitaker - https://forum.sentry.io/t/how-can-i-post-with-curl-a-sentry-event-which-authentication-credentials/4759/2?u=byk
echo "Creating test event..."
curl -sf --data '{"event_id": "'"$TEST_EVENT_ID"'","level":"error","message":"a failure","extra":{"object":"42"}}' -H 'Content-Type: application/json' -H "X-Sentry-Auth: Sentry sentry_version=7, sentry_key=$SENTRY_KEY, sentry_client=test-bash/0.1" "$SENTRY_TEST_HOST/api/$PROJECT_ID/store/" -o /dev/null

EVENT_PATH="projects/sentry/internal/events/$TEST_EVENT_ID/"
export -f sentry_api_request get_csrf_token
export SENTRY_TEST_HOST COOKIE_FILE EVENT_PATH
printf "Getting the test event back"
timeout 30 bash -c 'until $(sentry_api_request "$EVENT_PATH" -Isf -X GET -o /dev/null); do printf '.'; sleep 0.5; done'
echo "";

EVENT_RESPONSE=$(sentry_api_request "$EVENT_PATH")
declare -a EVENT_TEST_STRINGS=(
  '"eventID":"'"$TEST_EVENT_ID"'"'
  '"message":"a failure"'
  '"title":"a failure"'
  '"object":"42"'
)
for i in "${EVENT_TEST_STRINGS[@]}"
do
  echo "Testing '$i'..."
  echo "$EVENT_RESPONSE" | grep "$i[,}]" >& /dev/null
  echo "Pass."
done
