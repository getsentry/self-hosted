#!/bin/bash
set -eu

OLD_VERSION="$1"
NEW_VERSION="$2"

WAL2JSON_VERSION=${WAL2JSON_VERSION:-$(curl -s "https://api.github.com/repos/getsentry/wal2json/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')}

sed -i -e "s/^WAL2JSON_VERSION=\([^:]\+\):.\+\$/WAL2JSON_VERSION=\1:$WAL2JSON_VERSION/" .env
sed -i -e "s/^\(SENTRY\|SNUBA\|RELAY\|SYMBOLICATOR\)_IMAGE=\([^:]\+\):.\+\$/\1_IMAGE=\2:$NEW_VERSION/" .env
sed -i -e "s/^\# Self-Hosted Sentry .*/# Self-Hosted Sentry $NEW_VERSION/" README.md
sed -i -e "s/\(Change Date:\s*\)[-0-9]\+\$/\\1$(date +'%Y-%m-%d' -d '3 years')/" LICENSE

echo "New version: $NEW_VERSION"
echo "New wal2json version: $WAL2JSON_VERSION"
