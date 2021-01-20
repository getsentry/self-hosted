ARG SENTRY_IMAGE
FROM ${SENTRY_IMAGE}

COPY . /usr/src/sentry

# Hook for installing additional plugins
RUN if [ -s /usr/src/sentry/requirements.txt ]; then pip install -r /usr/src/sentry/requirements.txt; fi
