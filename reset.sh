#!/usr/bin/env bash

# The purpose of this script is to make it easy to reset a local onpremise
# install to a clean state, optionally installing a particular version/sha.

set -euo pipefail

if [ -n "${DEBUG:-}" ]; then
  set -x
fi

cd "$(dirname $0)"


function confirm () {
  read -p "$1 [y/n] " confirmation
  if [ "$confirmation" != "y" ]; then
    echo "Canceled. 😅"
    exit
  fi
}

# Make sure they mean it.
confirm "☠️  Warning! 😳 This is highly destructive! 😱 Are you sure you wish to proceed?"
echo "Okay ... good luck! 😰"

# Hit the reset button.
docker compose down --volumes

# Remove any remaining (likely external) volumes with name matching '.*sentry.*'.
for volume in $(docker volume list --format '{{ .Name }}' | grep sentry); do
  docker volume remove $volume > /dev/null \
    && echo "Removed volume: $volume" \
    || echo "Skipped volume: $volume"
done

# If we have a version (or other sha) given, install it.
ref="${1:-}"
if [ -z "$ref" ]; then
  exit
fi
git checkout "$ref"
exec ./install.sh
