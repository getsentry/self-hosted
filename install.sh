#!/usr/bin/env bash
set -eE

# Pre-pre-flight? 🤷
if [[ -n "$MSYSTEM" ]]; then
  echo "Seems like you are using an MSYS2-based system (such as Git Bash) which is not supported. Please use WSL instead."
  exit 1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/install/_lib.sh"

# Pre-flight. No impact yet.
source "$PROJECT_ROOT/install/parse-cli.sh"
source "$PROJECT_ROOT/install/detect-platform.sh"
source "$PROJECT_ROOT/install/dc-detect-version.sh"
source "$PROJECT_ROOT/install/error-handling.sh"
# We set the trap at the top level so that we get better tracebacks.
trap_with_arg cleanup ERR INT TERM EXIT
source "$PROJECT_ROOT/install/check-latest-commit.sh"
source "$PROJECT_ROOT/install/check-minimum-requirements.sh"

# Let's go! Start impacting things.
source "$PROJECT_ROOT/install/turn-things-off.sh"
source "$PROJECT_ROOT/install/create-docker-volumes.sh"
source "$PROJECT_ROOT/install/ensure-files-from-examples.sh"
source "$PROJECT_ROOT/install/ensure-relay-credentials.sh"
source "$PROJECT_ROOT/install/generate-secret-key.sh"
source "$PROJECT_ROOT/install/update-docker-images.sh"
source "$PROJECT_ROOT/install/build-docker-images.sh"
source "$PROJECT_ROOT/install/install-wal2json.sh"
source "$PROJECT_ROOT/install/bootstrap-snuba.sh"
source "$PROJECT_ROOT/install/create-kafka-topics.sh"
source "$PROJECT_ROOT/install/set-up-and-migrate-database.sh"
source "$PROJECT_ROOT/install/geoip.sh"
source "$PROJECT_ROOT/install/wrap-up.sh"
