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
# Upgrading clickhouse needs to come first before turning things off, since we need the old clickhouse image
# in order to determine whether or not the clickhouse version needs to be upgraded.
source install/upgrade-clickhouse.sh
source install/turn-things-off.sh
source install/update-docker-volume-permissions.sh
source install/create-docker-volumes.sh
source install/ensure-files-from-examples.sh
source install/check-memcached-backend.sh
source install/ensure-relay-credentials.sh
source install/generate-secret-key.sh
source install/update-docker-images.sh
source install/build-docker-images.sh
source install/bootstrap-snuba.sh
source install/upgrade-postgres.sh
source install/set-up-and-migrate-database.sh
source install/geoip.sh
source install/setup-js-sdk-assets.sh
source install/wrap-up.sh
