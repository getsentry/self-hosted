FROM getsentry/snuba:latest
RUN apt-get update && apt-get install -y cron && \
    rm -r /var/lib/apt/lists/*
# This is the cheapest and easiest way to create a cron job
RUN echo "\
    */5 * * * * /usr/local/bin/gosu snuba \
    /usr/local/bin/snuba cleanup --clickhouse-host clickhouse --dry-run False \
    > /proc/1/fd/1 2>/proc/1/fd/2 \
  " | crontab -
ENTRYPOINT ["/usr/sbin/cron"]
CMD ["-l", "-L", "15", "-f"]
