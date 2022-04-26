#!/usr/bin/env bash

if [ "$(ls -A /usr/local/share/ca-certificates/)" ]; then
  update-ca-certificates
fi

# Prior art:
# - https://github.com/renskiy/cron-docker-image/blob/5600db37acf841c6d7a8b4f3866741bada5b4622/debian/start-cron#L34-L36
# - https://blog.knoldus.com/running-a-cron-job-in-docker-container/

declare -p | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /container.env

{ for cron_job in "$@"; do echo -e "SHELL=/bin/bash
BASH_ENV=/container.env
${cron_job} > /proc/1/fd/1 2>/proc/1/fd/2"; done } \
  | sed --regexp-extended 's/\\(.)/\1/g' \
  | crontab -
crontab -l
exec cron -f -l -L 15
