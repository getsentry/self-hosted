#!/bin/bash

echo "${_group}Ensuring correct permissions on profiles directory ..."
$dc run -d --rm --entrypoint /bin/bash --user root vroom chown -R 1000:1000 /var/lib/sentry-profiles
echo "${_endgroup}"
