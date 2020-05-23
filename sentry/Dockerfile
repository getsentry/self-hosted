ARG SENTRY_VERSION=latest
ARG SENTRY_IMAGE
FROM ${SENTRY_IMAGE:-getsentry/sentry:$SENTRY_VERSION}

COPY . /usr/src/sentry

# Hook for installing additional plugins
RUN if [ -s /usr/src/sentry/requirements.txt ]; then pip install -r /usr/src/sentry/requirements.txt; fi
