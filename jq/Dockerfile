FROM debian:bookworm-slim

LABEL MAINTAINER="oss@sentry.io"

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG http_proxy
ARG https_proxy

RUN if [ -n "${HTTP_PROXY}" ]; then echo "Acquire::http::proxy \"${HTTP_PROXY}\";" >> /etc/apt/apt.conf; fi
RUN if [ -n "${HTTPS_PROXY}" ]; then echo "Acquire::https::proxy \"${HTTPS_PROXY}\";" >> /etc/apt/apt.conf; fi
RUN if [ -n "${http_proxy}" ]; then echo "Acquire::http::proxy \"${http_proxy}\";" >> /etc/apt/apt.conf; fi
RUN if [ -n "${https_proxy}" ]; then echo "Acquire::https::proxy \"${https_proxy}\";" >> /etc/apt/apt.conf; fi

RUN set -x \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends jq \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["jq"]
