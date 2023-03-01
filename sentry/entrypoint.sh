#!/bin/bash
set -e

if [ "$(ls -A /usr/local/share/ca-certificates/)" ]; then
  # for backups, let's redirect the console output to avoid it being written to backup file
  if [[ $SENTRY_BACKUP == true ]]; then
    update-ca-certificates >/dev/null
  else
    update-ca-certificates
  fi
fi

if [ -e /etc/sentry/requirements.txt ]; then
  echo "sentry/requirements.txt is deprecated, use sentry/enhance-image.sh - see https://github.com/getsentry/self-hosted#enhance-sentry-image"
fi

source /docker-entrypoint.sh
