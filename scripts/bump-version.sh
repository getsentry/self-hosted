#!/bin/bash
set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SCRIPT_DIR/..

OLD_VERSION="$1"
NEW_VERSION="$2"

SYMBOLICATOR_VERSION=$(curl -sSL 'https://api.github.com/repos/getsentry/symbolicator/git/refs/heads/master' | grep -Po '(?<=\"sha\": \")([a-f0-9]{5,40})(?=\",?)')

sed -i -e "s/^SYMBOLICATOR_IMAGE=\([^:]\+\):.\+\$/SYMBOLICATOR_IMAGE=\1:$SYMBOLICATOR_VERSION/" .env
sed -i -e "s/^\(SENTRY\|SNUBA\|RELAY\)_IMAGE=\([^:]\+\):.\+\$/\1_IMAGE=\2:$NEW_VERSION/" .env
sed -i -e "s/^\# Sentry .* On-Premise/# Sentry $NEW_VERSION On-Premise/" README.md
sed -i -e "s/\(Change Date:\s*\)[-0-9]\+\$/\\1$(date +'%Y-%m-%d' -d '3 years')/" LICENSE

echo "New version: $NEW_VERSION"
echo "New Symbolicator version: $SYMBOLICATOR_VERSION"
