#!/bin/bash
set -eu

OLD_VERSION="$1"
NEW_VERSION="$2"

sed -i -e "s/^\(SENTRY\|SNUBA\|RELAY\|SYMBOLICATOR\|VROOM\)_IMAGE=\([^:]\+\):.\+\$/\1_IMAGE=\2:$NEW_VERSION/" .env
sed -i -e "s/^\# Self-Hosted Sentry .*/# Self-Hosted Sentry $NEW_VERSION/" README.md

echo "New version: $NEW_VERSION"
