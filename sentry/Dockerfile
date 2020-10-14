ARG SENTRY_IMAGE
ARG SENTRY_PYTHON3
FROM ${SENTRY_IMAGE}${SENTRY_PYTHON3:+-py3}

COPY . /usr/src/sentry

# Hook for installing additional plugins
RUN if [ -s /usr/src/sentry/requirements.txt ]; then pip install -r /usr/src/sentry/requirements.txt; fi
