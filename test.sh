#!/usr/bin/env bash
set -e

TEST_USER='test@sentry.io'
TEST_PASS='test123TEST'
COOKIE_FILE=$(mktemp)
declare -a TEST_STRINGS=(
    '"isAuthenticated":true'
    '"username":"test@sentry.io"'
    '"isSuperuser":true'
)

INITIAL_AUTH_REDIRECT=$(curl -sL -o /dev/null http://localhost:9000 -w %{url_effective})
if [ "$INITIAL_AUTH_REDIRECT" != "http://localhost:9000/auth/login/sentry/" ]; then
    echo "Initial /auth/login/ redirect failed, exiting..."
    echo "$INITIAL_AUTH_REDIRECT"
    exit -1
fi

CSRF_TOKEN=$(curl http://localhost:9000 -sL -c "$COOKIE_FILE" | awk -F "'" '
    /csrfmiddlewaretoken/ {
      print $4 "=" $6;
      exit;
    }')
LOGIN_RESPONSE=$(curl -sL -F 'op=login' -F "username=$TEST_USER" -F "password=$TEST_PASS" -F "$CSRF_TOKEN" http://localhost:9000/auth/login/ -H 'Referer: http://localhost/auth/login/' -b "$COOKIE_FILE" -c "$COOKIE_FILE")

TEST_RESULT=0
for i in "${TEST_STRINGS[@]}"
do
   echo "Testing '$i'..."
   echo "$LOGIN_RESPONSE" | grep "$i[,}]" >& /dev/null
   echo "Pass."
done
