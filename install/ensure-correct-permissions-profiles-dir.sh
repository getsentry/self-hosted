#!/bin/bash

# TODO: Remove this after the next hard-stop

echo "${_group}Ensuring correct permissions on profiles directory ..."
$dcr --no-deps --entrypoint /bin/bash --user root vroom -c 'chown -R vroom:vroom /var/lib/sentry-profiles && chmod o+x /var/lib/ && chmod -R o+rwx /var/lib/sentry-profiles && ls -la /var/lib/sentry-profiles && ls -la /var/lib'
echo "${_endgroup}"
