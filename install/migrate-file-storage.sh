echo "${_group}Migrating file storage ..."

SENTRY_DATA_NEEDS_MIGRATION=$(docker run --rm -v sentry-data:/data alpine ash -c "[ ! -d '/data/files' ] && ls -A1x /data | wc -l || true")
if [[ -n "$SENTRY_DATA_NEEDS_MIGRATION" ]]; then
  # Use the web (Sentry) image so the file owners are kept as sentry:sentry
  # The `\"` escape pattern is to make this compatible w/ Git Bash on Windows. See #329.
  $dcr --entrypoint \"/bin/bash\" web -c \
    "mkdir -p /tmp/files; mv /data/* /tmp/files/; mv /tmp/files /data/files; chown -R sentry:sentry /data"
fi

echo "${_endgroup}"
