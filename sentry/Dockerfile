ARG SENTRY_IMAGE
FROM ${SENTRY_IMAGE}

COPY . /usr/src/sentry

RUN if [ -s /usr/src/sentry/enhance-image.sh ]; then /usr/src/sentry/enhance-image.sh; fi
RUN if [ -s /usr/src/sentry/requirements.txt ]; then pip install -r /usr/src/sentry/requirements.txt; fi
