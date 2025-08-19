#!/usr/bin/env bash

# TODO: Remove this after the next hard-stop

echo "${_group}Ensuring correct permissions on profiles directory ..."

# Check if the parent directory of /var/vroom/sentry-profiles is already owned by vroom:vroom
if [ "$(stat -c '%U:%G' /var/vroom)" = "vroom:vroom" ]; then
  echo "Ownership of /var/vroom is already set to vroom:vroom. Skipping chown."
else
  $dcr --no-deps --entrypoint /bin/bash --user root vroom -c 'chown -R vroom:vroom /var/vroom/sentry-profiles && chmod -R o+rwx /var/vroom/sentry-profiles'
fi

echo "${_endgroup}"
