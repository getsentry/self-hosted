#!/bin/bash
set -e

if [ "$(ls -A /usr/local/share/ca-certificates/)" ]; then
  update-ca-certificates
fi

if [ -e /etc/sentry/requirements.txt ]; then
  echo "sentry/requirements.txt is deprecated, use sentry/enhance-image.sh"
fi

source /docker-entrypoint.sh
