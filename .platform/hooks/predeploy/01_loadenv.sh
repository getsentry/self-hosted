#!/bin/bash

set -e
/opt/elasticbeanstalk/bin/get-config environment | jq -r 'to_entries | .[] | "\(.key)=\"\(.value)\""' > .env
printf "SENTRY_IMAGE=getsentry/sentry:23.12.1" >> .env
set -a
source .env
set +a
wait
