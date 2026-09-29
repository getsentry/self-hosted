ARG SENTRY_IMAGE
FROM ${SENTRY_IMAGE}

# Customizations below need root. Newer sentry images default to the non-root
# `sentry` user, so switch explicitly and switch back at the end.
USER 0

RUN pip install https://github.com/getsentry/sentry-nodestore-s3/archive/main.zip

COPY . /usr/src/sentry

RUN if [ -s /usr/src/sentry/enhance-image.sh ]; then \
    /usr/src/sentry/enhance-image.sh; \
    fi

RUN if [ -s /usr/src/sentry/requirements.txt ]; then \
    echo "sentry/requirements.txt is deprecated, use sentry/enhance-image.sh - see https://develop.sentry.dev/self-hosted/#enhance-sentry-image"; \
    pip install -r /usr/src/sentry/requirements.txt; \
    fi

# Let the non-root sentry user run update-ca-certificates (sentry/entrypoint.sh)
# for custom CAs mounted from ./certificates. It only needs to create symlinks
# and replace the bundle in this directory.
RUN chown sentry:sentry /etc/ssl/certs

USER sentry
