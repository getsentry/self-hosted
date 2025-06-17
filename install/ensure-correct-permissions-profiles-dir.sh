#!/bin/bash

echo "${_group}Ensuring correct permissions on profiles directory ..."
docker run --user root --rm -v sentry-vroom:/var/lib/sentry-profiles alpine chown -R 1000:1000 /var/lib/sentry-profiles
echo "${_endgroup}"
