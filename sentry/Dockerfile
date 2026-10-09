ARG SENTRY_IMAGE
FROM ${SENTRY_IMAGE}

# Customizations below need root. Newer sentry images default to the non-root
# `sentry` user, so switch explicitly and switch back at the end.
USER 0

# Only exec-form RUNs: the sentry image may not have a shell.
RUN ["python3", "-m", "pip", "install", "https://github.com/getsentry/sentry-nodestore-s3/archive/main.zip"]

COPY . /usr/src/sentry

RUN ["python3", "/usr/src/sentry/customize_image.py"]

USER sentry
