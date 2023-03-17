#!/usr/bin/env bash

# The purpose of this script is to make it easy to reset a local self-hosted
# install to a clean state, optionally targeting a particular version.

if [ -n "${DEBUG:-}" ]; then
  set -x
fi

function confirm() {
  read -p "$1 [y/n] " confirmation
  if [ "$confirmation" != "y" ]; then
    echo "Canceled. 😅"
    exit
  fi
}

function clean() {
  # If we have a version given, validate it.
  # ----------------------------------------
  # Note that arbitrary git refs won't work, because the *_IMAGE variables in
  # .env will almost certainly point to :latest. Tagged releases are generally
  # the only refs where these component versions are pinned, so enforce that
  # we're targeting a valid tag here. Do this early in order to fail fast.
  if [ -n "$version" ]; then
    set +e
    git rev-parse --verify --quiet "refs/tags/$version" >/dev/null
    if [ $? -gt 0 ]; then
      echo "Bad version: $version"
      exit
    fi
    set -e
  fi

  false "noooo"

  # Make sure they mean it.
  if [ "${FORCE_CLEAN:-}" == "1" ]; then
    echo "☠️  Seeing FORCE=1, forcing cleanup."
    echo
  else
    confirm "☠️  Warning! 😳 This is highly destructive! 😱 Are you sure you wish to proceed?"
    echo "Okay ... good luck! 😰"
  fi

  # Hit the reset button.
  $dc down --volumes --remove-orphans --rmi local

  # Remove any remaining (likely external) volumes with name matching 'sentry-.*'.
  for volume in $(docker volume list --format '{{ .Name }}' | grep '^sentry-'); do
    docker volume remove $volume >/dev/null &&
      echo "Removed volume: $volume" ||
      echo "Skipped volume: $volume"
  done

  # If we have a version given, switch to it.
  if [ -n "$version" ]; then
    git checkout "$version"
  fi
}

function backup() {
  chmod +w $(pwd)/sentry
  docker-compose run -v $(pwd)/sentry:/sentry-data/backup --rm -T -e SENTRY_LOG_LEVEL=CRITICAL web export /sentry-data/backup/backup.json
}

function restore() {
  docker-compose run --rm -T web import /etc/sentry/backup.json
}
