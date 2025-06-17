#!/bin/bash

# TODO: Remove this after the next hard-stop

echo "${_group}Ensuring correct permissions on profiles directory ..."
$dcr --entrypoint /bin/bash --user root vroom -c 'chown -R vroom:vroom /var/lib/sentry-profiles'
echo "${_endgroup}"
