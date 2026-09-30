ARG SENTRY_IMAGE
FROM ${SENTRY_IMAGE}

USER 0
RUN ["python3", "-m", "pip", "install", "--no-cache-dir", "https://github.com/getsentry/sentry-nodestore-s3/archive/main.zip"]
USER sentry
