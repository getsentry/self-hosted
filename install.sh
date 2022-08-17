#!/usr/bin/env bash
set -eE

export SENTRY_DSN='https://5a620019b5124cbba230a9e62db9b825@o1.ingest.sentry.io/6627632'
#export SENTRY_ORG=sentry-self-hosted
#export SENTRY_PROJECT=dogfooding

function err_info {
  local retcode=$?
  local cmd="${BASH_COMMAND}"
  if [[ $retcode -ne 0 ]]; then
    set +o xtrace
    echo "Error in ${BASH_SOURCE[0]}:${BASH_LINENO[0]}." >&2
    echo "'$cmd' exited with status $retcode" >&2
    local stack_depth=${#FUNCNAME[@]}
    if [ $stack_depth -gt 2 ]; then
      for ((i=$(($stack_depth - 1)),j=1;i>0;i--,j++)); do
          local indent="$(yes a | head -$j | tr -d '\n')"
          local src=${BASH_SOURCE[$i]}
          local lineno=${BASH_LINENO[$i-1]}
          local funcname=${FUNCNAME[$i]}
          echo "${indent//a/-}>$src:$funcname:$lineno" >&2
      done
    fi
  fi
  echo "Exiting with code $retcode" >&2
  exit $retcode
}
trap 'err_info' EXIT

# Pre-pre-flight? 🤷
if [[ -n "$MSYSTEM" ]]; then
  echo "Seems like you are using an MSYS2-based system (such as Git Bash) which is not supported. Please use WSL instead.";
  exit 1
fi

source "$(dirname $0)/install/_lib.sh"  # does a `cd .../install/`, among other things

# Pre-flight. No impact yet.
source parse-cli.sh
source dc-detect-version.sh
source error-handling.sh
source check-latest-commit.sh
source check-minimum-requirements.sh

# Let's go! Start impacting things.
source turn-things-off.sh
source create-docker-volumes.sh
source ensure-files-from-examples.sh
source ensure-relay-credentials.sh
source generate-secret-key.sh
source replace-tsdb.sh
source update-docker-images.sh
source build-docker-images.sh
source set-up-zookeeper.sh
source install-wal2json.sh
source bootstrap-snuba.sh
source create-kafka-topics.sh
source upgrade-postgres.sh
source set-up-and-migrate-database.sh
source migrate-file-storage.sh
source geoip.sh
source wrap-up.sh
