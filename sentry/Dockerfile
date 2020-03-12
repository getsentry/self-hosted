ARG SENTRY_IMAGE
FROM ${SENTRY_IMAGE:-getsentry/sentry:latest}

COPY . /usr/src/sentry

# Hook for installing additional plugins
RUN if [ -s requirements.txt ]; then pip install -r requirements.txt; fi
