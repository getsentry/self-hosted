#!/usr/bin/env bash

# TODO: Remove this after the next hard-stop

echo "${_group}Ensuring correct permissions on profiles directory ..."

# Check if the parent directory of /var/vroom/sentry-profiles is already owned by vroom:vroom
$dcr --no-deps --entrypoint /bin/bash --user root vroom -c '
  if [ "$(stat -c "%U:%G" /var/vroom/sentry-profiles 2>/dev/null)" = "vroom:vroom" ]; then
    echo "Ownership already correct. Skipping chown."
  else
    chown -R vroom:vroom /var/vroom/sentry-profiles \
    && chmod -R o+rwx /var/vroom/sentry-profiles
  fi
'

echo "${_endgroup}"
