#!/usr/bin/env bash

# The purpose of this script is to make it easy to reset a local self-hosted
# install to a clean state, optionally targeting a particular version.

set -euo pipefail

if [ -n "${DEBUG:-}" ]; then
  set -x
fi

cd "$(dirname $0)"

source install/dc-detect-version.sh

function confirm () {
  read -p "$1 [y/n] " confirmation
  if [ "$confirmation" != "y" ]; then
    echo "Canceled. 😅"
    exit
  fi
}


# If we have a version given, validate it.
# ----------------------------------------
# Note that arbitrary git refs won't work, because the *_IMAGE variables in
# .env will almost certainly point to :latest. Tagged releases are generally
# the only refs where these component versions are pinned, so enforce that
# we're targeting a valid tag here. Do this early in order to fail fast.

version="${1:-}"
if [ -n "$version" ]; then
  set +e
  git rev-parse --verify --quiet "refs/tags/$version" > /dev/null
  if [ $? -gt 0 ]; then
    echo "Bad version: $version"
    exit
  fi
  set -e
fi

# Make sure they mean it.
confirm "☠️  Warning! 😳 This is highly destructive! 😱 Are you sure you wish to proceed?"
echo "Okay ... good luck! 😰"

# Hit the reset button.
$dc down --volumes --remove-orphans --rmi local

# Remove any remaining (likely external) volumes with name matching 'sentry-.*'.
for volume in $(docker volume list --format '{{ .Name }}' | grep '^sentry-'); do
  docker volume remove $volume > /dev/null \
    && echo "Removed volume: $volume" \
    || echo "Skipped volume: $volume"
done

# If we have a version given, switch to it.
if [ -n "$version" ]; then
  git checkout "$version"
fi

# Install.
./install.sh
