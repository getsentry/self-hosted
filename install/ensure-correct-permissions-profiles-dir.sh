#!/bin/bash

# TODO: Remove this after the next hard-stop

echo "${_group}Ensuring correct permissions on profiles directory ..."
$dcr --no-deps --entrypoint /bin/bash --user root vroom -c 'chown -R vroom:vroom /var/vroom/sentry-profiles && chmod -R o+rwx /var/vroom/sentry-profiles'
echo "${_endgroup}"
