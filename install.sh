#!/usr/bin/env bash
set -eE

# Pre-pre-flight? 🤷
if [[ -n "$MSYSTEM" ]]; then
  echo "Seems like you are using an MSYS2-based system (such as Git Bash) which is not supported. Please use WSL instead."
  exit 1
fi

source install/_lib.sh

# Pre-flight. No impact yet.
source install/parse-cli.sh
source install/detect-platform.sh
source install/dc-detect-version.sh
source install/error-handling.sh
# We set the trap at the top level so that we get better tracebacks.
trap_with_arg cleanup ERR INT TERM EXIT
source install/check-latest-commit.sh
source install/check-minimum-requirements.sh

# Let's go! Start impacting things.
source install/turn-things-off.sh
source install/create-docker-volumes.sh
source install/ensure-files-from-examples.sh
source install/ensure-relay-credentials.sh
source install/generate-secret-key.sh
source install/update-docker-images.sh
source install/build-docker-images.sh
source install/install-wal2json.sh
source install/bootstrap-snuba.sh
source install/create-kafka-topics.sh
source install/upgrade-postgres.sh
source install/set-up-and-migrate-database.sh
source install/geoip.sh
source install/wrap-up.sh
