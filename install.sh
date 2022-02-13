#!/usr/bin/env bash
set -e

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
