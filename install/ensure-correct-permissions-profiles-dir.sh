#!/usr/bin/env bash

# TODO: Remove this after the next hard-stop

# Should only run when `$COMPOSE_PROFILES` is set to `feature-complete`
if [[ "$COMPOSE_PROFILES" == "feature-complete" ]]; then
  echo "${_group}Ensuring correct permissions on profiles directory ..."

  # Check if `/var/vroom/sentry-profiles` directory exists. If it doesn't, skip this.
  if [ ! $dcr --no-deps --entrypoint /bin/bash --user root vroom -c "test -d /var/vroom/sentry-profiles" ] 2>/dev/null; then
    echo "/var/vroom/sentry-profiles directory does not exist. Skipping permissions check."
    echo "${_endgroup}"
  else
    # Check if the parent directory of /var/vroom/sentry-profiles is already owned by vroom:vroom
    if [ "$($dcr --no-deps --entrypoint /bin/bash --user root vroom -c "stat -c '%U:%G' /var/vroom/sentry-profiles" 2>/dev/null)" = "vroom:vroom" ]; then
      echo "Ownership of /var/vroom/sentry-profiles is already set to vroom:vroom. Skipping chown."
    else
      $dcr --no-deps --entrypoint /bin/bash --user root vroom -c 'chown -R vroom:vroom /var/vroom/sentry-profiles && chmod -R o+rwx /var/vroom/sentry-profiles'
    fi
  fi

  echo "${_endgroup}"
fi
