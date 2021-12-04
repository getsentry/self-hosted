#!/usr/bin/env bash
set -e
if [[ -n "$MSYSTEM" ]]; then
  echo "Seems like you are using an MSYS2-based system (such as Git Bash) which is not supported. Please use WSL instead.";
  exit 1
fi

if [[ $(git branch | sed -n '/\* /s///p') == "master" ]]; then
  if [[ $(git rev-parse HEAD) != $(git ls-remote $(git rev-parse --abbrev-ref @{u} | sed 's/\// /g') | cut -f1) ]]; then
    echo "Seems like you are not using the latest commit from self-hosted repository. Please pull the latest changes and try again.";
    exit 1
  fi
fi

source "$(dirname $0)/install/_lib.sh"  # does a `cd .../install/`, among other things

source parse-cli.sh
source error-handling.sh
source check-minimum-requirements.sh
source create-docker-volumes.sh
source ensure-files-from-examples.sh
source generate-secret-key.sh
source replace-tsdb.sh
source update-docker-images.sh
source build-docker-images.sh
source turn-things-off.sh
source set-up-zookeeper.sh
source install-wal2json.sh
source bootstrap-snuba.sh
source create-kafka-topics.sh
source upgrade-postgres.sh
source set-up-and-migrate-database.sh
source migrate-file-storage.sh
source relay-credentials.sh
source geoip.sh
source wrap-up.sh
