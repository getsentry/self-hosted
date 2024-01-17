#!/bin/bash

set -e
/opt/elasticbeanstalk/bin/get-config environment | jq -r 'to_entries | .[] | "\(.key)=\"\(.value)\""' > .env
printf "SENTRY_IMAGE=getsentry/sentry:23.12.1" >> .env
export $(cat .env | xargs)
docker image prune -f
./install.sh --no-user-prompt --no-report-self-hosted-issues
wait
