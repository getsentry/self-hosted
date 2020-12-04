ARG SENTRY_IMAGE
ARG SENTRY_PYTHON
FROM ${SENTRY_IMAGE}-py${SENTRY_PYTHON:-3}

COPY . /usr/src/sentry

# Hook for installing additional plugins
RUN if [ -s /usr/src/sentry/requirements.txt ]; then pip install -r /usr/src/sentry/requirements.txt; fi
