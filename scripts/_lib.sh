#!/usr/bin/env bash

set -eEuo pipefail

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

# The purpose of this script is to make it easy to reset a local self-hosted
# install to a clean state, optionally targeting a particular version.

function reset() {
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
  type=${1:-"global"}
  touch $(pwd)/sentry/backup.json
  chmod 666 $(pwd)/sentry/backup.json
  $dc run -v $(pwd)/sentry:/sentry-data/backup --rm -T -e SENTRY_LOG_LEVEL=CRITICAL web export $type /sentry-data/backup/backup.json
}

function restore() {
  type=${1:-"global"}
  $dc run --rm -T web import $type /etc/sentry/backup.json
}

# Needed variables to source error-handling script
MINIMIZE_DOWNTIME="${MINIMIZE_DOWNTIME:-}"
STOP_TIMEOUT=60

# Save logs in order to send envelope to Sentry
log_file=sentry_"$cmd"_log-$(date +'%Y-%m-%d_%H-%M-%S').txt
exec &> >(tee -a "$log_file")
version=""

while (($#)); do
  case "$1" in
  --report-self-hosted-issues) REPORT_SELF_HOSTED_ISSUES=1 ;;
  --no-report-self-hosted-issues) REPORT_SELF_HOSTED_ISSUES=0 ;;
  *) version=$1 ;;
  esac
  shift
done

# Source files needed to set up error-handling
source install/dc-detect-version.sh
source install/detect-platform.sh
source install/error-handling.sh
trap_with_arg cleanup ERR INT TERM EXIT
