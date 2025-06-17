#!/bin/bash

echo "${_group}Ensuring correct permissions on profiles directory ..."
$dc run --rm vroom chown -R 1000:1000 /var/lib/sentry-profiles
echo "${_endgroup}"
