#!/usr/bin/env bash

# The purpose of this script is to make it easy to reset a local onpremise
# install to a clean state, optionally installing a particular version/ref.

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
docker compose down --volumes --rmi local

# Remove any remaining (likely external) volumes with name matching '.*sentry.*'.
for volume in $(docker volume list --format '{{ .Name }}' | grep sentry); do
  docker volume remove $volume > /dev/null \
    && echo "Removed volume: $volume" \
    || echo "Skipped volume: $volume"
done

# If we have a version given, switch to it.

# Note that arbitrary git refs won't work, because the *_IMAGE variables in
# .env will almost certainly point to :latest. Release tags of onpremise are
# generally the only refs where these component versions are pinned.

version="${1:-}"
if [ -n "$version" ]; then
  git checkout "$version"
fi

# Install.
exec ./install.sh
