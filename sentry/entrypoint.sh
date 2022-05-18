#!/bin/bash
set -e

if [ "$(ls -A /usr/local/share/ca-certificates/)" ]; then
  update-ca-certificates
fi

source /docker-entrypoint.sh
