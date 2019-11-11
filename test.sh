#!/usr/bin/env bash
set -e

SENTRY_TEST_HOST="${SENTRY_TEST_HOST:-http://localhost:9000}"
TEST_USER='test@example.com'
TEST_PASS='test123TEST'
COOKIE_FILE=$(mktemp)
declare -a TEST_STRINGS=(
    '"isAuthenticated":true'
    '"username":"test@example.com"'
    '"isSuperuser":true'
)

INITIAL_AUTH_REDIRECT=$(curl -sL -o /dev/null $SENTRY_TEST_HOST -w %{url_effective})
if [ "$INITIAL_AUTH_REDIRECT" != "$SENTRY_TEST_HOST/auth/login/sentry/" ]; then
    echo "Initial /auth/login/ redirect failed, exiting..."
    echo "$INITIAL_AUTH_REDIRECT"
    exit -1
fi

CSRF_TOKEN=$(curl $SENTRY_TEST_HOST -sL -c "$COOKIE_FILE" | awk -F "'" '
    /csrfmiddlewaretoken/ {
      print $4 "=" $6;
      exit;
    }')
LOGIN_RESPONSE=$(curl -sL -F 'op=login' -F "username=$TEST_USER" -F "password=$TEST_PASS" -F "$CSRF_TOKEN" "$SENTRY_TEST_HOST/auth/login/" -H "Referer: $SENTRY_TEST_HOST/auth/login/" -b "$COOKIE_FILE" -c "$COOKIE_FILE")

TEST_RESULT=0
for i in "${TEST_STRINGS[@]}"
do
   echo "Testing '$i'..."
   echo "$LOGIN_RESPONSE" | grep "$i[,}]" >& /dev/null
   echo "Pass."
done
