#!/bin/bash

echo "${_group}Ensuring correct permissions on profiles directory ..."
$dc run --entrypoint /bin/bash --rm vroom -c 'chown -R 1000:1000 /var/lib/sentry-profiles'
echo "${_endgroup}"
