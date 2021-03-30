echo "${_group}Ensuring proper PostgreSQL version ..."

# Very naively check whether there's an existing sentry-postgres volume and the PG version in it
if [[ -n "$(docker volume ls -q --filter name=sentry-postgres)" && "$(docker run --rm -v sentry-postgres:/db busybox cat /db/PG_VERSION 2>/dev/null)" == "9.5" ]]; then
  docker volume rm sentry-postgres-new || true
  # If this is Postgres 9.5 data, start upgrading it to 9.6 in a new volume
  docker run --rm \
  -v sentry-postgres:/var/lib/postgresql/9.5/data \
  -v sentry-postgres-new:/var/lib/postgresql/9.6/data \
  tianon/postgres-upgrade:9.5-to-9.6

  # Get rid of the old volume as we'll rename the new one to that
  docker volume rm sentry-postgres
  docker volume create --name sentry-postgres
  # There's no rename volume in Docker so copy the contents from old to new name
  # Also append the `host all all all trust` line as `tianon/postgres-upgrade:9.5-to-9.6`
  # doesn't do that automatically.
  docker run --rm -v sentry-postgres-new:/from -v sentry-postgres:/to alpine ash -c \
    "cd /from ; cp -av . /to ; echo 'host all all all trust' >> /to/pg_hba.conf"
  # Finally, remove the new old volume as we are all in sentry-postgres now
  docker volume rm sentry-postgres-new
fi

echo "${_endgroup}"
