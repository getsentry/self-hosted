ARG SENTRY_IMAGE
FROM ${SENTRY_IMAGE}

RUN pip install git+https://github.com/getsentry/sentry-nodestore-s3.git@508246183499908232517200229ad5118e147331

COPY . /usr/src/sentry

RUN if [ -s /usr/src/sentry/enhance-image.sh ]; then \
    /usr/src/sentry/enhance-image.sh; \
    fi

RUN if [ -s /usr/src/sentry/requirements.txt ]; then \
    echo "sentry/requirements.txt is deprecated, use sentry/enhance-image.sh - see https://develop.sentry.dev/self-hosted/#enhance-sentry-image"; \
    pip install -r /usr/src/sentry/requirements.txt; \
    fi
