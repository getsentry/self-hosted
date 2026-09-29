#!/bin/bash
set -e

# Trust custom CA certificates mounted from ./certificates. Sentry containers run
# as the non-root `sentry` user, so instead of update-ca-certificates (which
# needs root) build a combined bundle in /tmp and point the TLS env vars at it.
# Messages go to stderr so they don't pollute the output of commands like `cat`.
custom_certs=$(find -L /usr/local/share/ca-certificates -type f -name '*.crt' -not -path '*/.generated/*' 2>/dev/null | sort)
if [ -n "$custom_certs" ]; then
  system_bundle=/etc/ssl/certs/ca-certificates.crt
  bundle=/tmp/sentry-ca-certificates.crt
  cat "$system_bundle" >"$bundle"
  while IFS= read -r cert; do
    cat "$cert" >>"$bundle"
    echo >>"$bundle"
  done <<<"$custom_certs"
  echo "Added $(wc -l <<<"$custom_certs") custom CA certificate(s) to $bundle" >&2

  # Only redirect variables that are unset or still point at the system bundle,
  # so explicit user overrides keep working.
  for var in SSL_CERT_FILE REQUESTS_CA_BUNDLE DEFAULT_CA_BUNDLE GRPC_DEFAULT_SSL_ROOTS_FILE_PATH_ENV_VAR; do
    if [ -z "${!var:-}" ] || [ "${!var}" = "$system_bundle" ]; then
      export "$var=$bundle"
    fi
  done
fi

if [ -e /etc/sentry/requirements.txt ]; then
  echo "sentry/requirements.txt is deprecated, use sentry/enhance-image.sh - see https://develop.sentry.dev/self-hosted/#enhance-sentry-image"
fi

source /docker-entrypoint.sh
