#!/bin/bash

# TODO: Remove this after the next hard-stop

echo "${_group}Ensuring correct permissions on profiles directory ..."

# If COMPOSE_PROFILES wasn't set before, we'll set it to "feature-complete".
# If it was previously set to "feature-complete", we'll keep it as such.
# Otherwise, we'll need to unset it.
profiles_was_not_set=0
if [ -z "${COMPOSE_PROFILES:-}" ]; then
  export COMPOSE_PROFILES="feature-complete"
  profiles_was_not_set=1
fi

# Ensure permissions are correct
$dcr --no-deps --entrypoint /bin/bash --user root vroom -c 'chown -R vroom:vroom /var/vroom/sentry-profiles && chmod -R o+rwx /var/vroom/sentry-profiles'

# Unset the variable
if [ "$profiles_was_not_set" -eq 1 ]; then
  unset COMPOSE_PROFILES
fi

echo "${_endgroup}"
