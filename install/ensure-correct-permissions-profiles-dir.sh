#!/bin/bash

# TODO: Remove this after the next hard-stop

echo "${_group}Ensuring correct permissions on profiles directory ..."
$dcr --rm --no-deps --entrypoint /bin/bash vroom -c 'chown -R 1000:1000 /var/lib/sentry-profiles'
echo "${_endgroup}"
