ARG BASE_IMAGE
FROM ${BASE_IMAGE}
USER 0
RUN if [ -n "${http_proxy}" ]; then echo "Acquire::http::proxy \"${http_proxy}\";" >> /etc/apt/apt.conf; fi
RUN if [ -n "${https_proxy}" ]; then echo "Acquire::https::proxy \"${https_proxy}\";" >> /etc/apt/apt.conf; fi
RUN apt-get update && apt-get install -y --no-install-recommends cron && \
    rm -r /var/lib/apt/lists/*
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
