#!/usr/bin/env bash
set -eu

OLD_VERSION="$1"
NEW_VERSION="$2"

sed -i -e "s/^\(SENTRY\|SNUBA\|RELAY\|SYMBOLICATOR\|TASKBROKER\|VROOM\|UPTIME_CHECKER\)_IMAGE=\([^:]\+\):.\+\$/\1_IMAGE=\2:$NEW_VERSION/" .env
sed -i -e "s/^\# Self-Hosted Sentry .*/# Self-Hosted Sentry $NEW_VERSION/" README.md

[ -z "$OLD_VERSION" ] || echo "Previous version: $OLD_VERSION"
echo "New version: $NEW_VERSION"
