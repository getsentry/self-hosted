echo "${_group}Ensuring proper PostgreSQL version ..."

postgres_version=$($CONTAINER_ENGINE run --rm -v sentry-postgres:/db busybox sh -c 'for data in /db /db/18/docker; do if [ -f "$data/PG_VERSION" ]; then cat "$data/PG_VERSION"; break; fi; done')

if [[ -n "$($CONTAINER_ENGINE volume ls -q --filter name=sentry-postgres)" && "$($CONTAINER_ENGINE run --rm -v sentry-postgres:/db busybox cat /db/PG_VERSION 2>/dev/null)" == "9.6" ]]; then
  $CONTAINER_ENGINE volume rm sentry-postgres-new || true
  # If this is Postgres 9.6 data, start upgrading it to 14.0 in a new volume
  $CONTAINER_ENGINE run --rm \
    -v sentry-postgres:/var/lib/postgresql/9.6/data \
    -v sentry-postgres-new:/var/lib/postgresql/14/data \
    tianon/postgres-upgrade:9.6-to-14

  # Get rid of the old volume as we'll rename the new one to that
  $CONTAINER_ENGINE volume rm sentry-postgres
  $CONTAINER_ENGINE volume create --name sentry-postgres
  # There's no rename volume in Docker so copy the contents from old to new name
  # Also append the `host all all all trust` line as `tianon/postgres-upgrade:9.6-to-14`
  # doesn't do that automatically.
  $CONTAINER_ENGINE run --rm -v sentry-postgres-new:/from -v sentry-postgres:/to alpine ash -c \
    "cd /from ; cp -av . /to ; echo 'host all all all trust' >> /to/pg_hba.conf"
  # Finally, remove the new old volume as we are all in sentry-postgres now.
  $CONTAINER_ENGINE volume rm sentry-postgres-new
  echo "Re-indexing due to glibc change, this may take a while..."
  echo "Starting up new PostgreSQL version"
  start_service_and_wait_ready postgres

  # Wait for postgres
  RETRIES=5
  until $dc exec postgres psql -U postgres -c "select 1" >/dev/null 2>&1 || [ $RETRIES -eq 0 ]; do
    echo "Waiting for postgres server, $((RETRIES--)) remaining attempts..."
    sleep 1
  done

  # VOLUME_NAME is the same as container name
  # Reindex all databases and their system catalogs which are not templates
  DBS=$($dc exec postgres psql -qAt -U postgres -c "SELECT datname FROM pg_database WHERE datistemplate = false;")
  for db in ${DBS}; do
    echo "Re-indexing database: ${db}"
    $dc exec postgres psql -qAt -U postgres -d ${db} -c "reindex system ${db}"
    $dc exec postgres psql -qAt -U postgres -d ${db} -c "reindex database ${db};"
  done

  $dc stop postgres
fi

if $CONTAINER_ENGINE volume inspect sentry-postgres-new >/dev/null 2>&1; then
  echo "Found sentry-postgres-new from an interrupted PostgreSQL upgrade. Recover the database before removing this volume and rerunning install.sh."
  exit 1
fi

if [[ "$postgres_version" == "14" ]]; then
  if ! $CONTAINER_ENGINE run --rm -v sentry-postgres:/db:ro busybox test -f /db/14-trixie-reindexed; then
    echo "Sentry 26.9.0 is a required hard stop. Upgrade to 26.9.0 and complete its PostgreSQL 14 Trixie migration before upgrading to PostgreSQL 18."
    exit 1
  fi

  $CONTAINER_ENGINE run --rm \
    -e POSTGRES_INITDB_ARGS=--no-data-checksums \
    -v sentry-postgres:/var/lib/postgresql/14/data \
    -v sentry-postgres-new:/var/lib/postgresql/18/docker \
    tianon/postgres-upgrade:14-to-18

  $CONTAINER_ENGINE volume rm sentry-postgres
  $CONTAINER_ENGINE volume create --name sentry-postgres
  $CONTAINER_ENGINE run --rm -v sentry-postgres-new:/from -v sentry-postgres:/to alpine ash -ec \
    "mkdir -p /to/18/docker; cp -av /from/. /to/18/docker; echo 'host all all all trust' >> /to/18/docker/pg_hba.conf"
  $CONTAINER_ENGINE volume rm sentry-postgres-new
  postgres_version=18
fi

# Reindex existing PostgreSQL 14 data once for the glibc 2.36 (Bookworm) -> 2.41 (Trixie) change.
if [[ "$postgres_version" == "14" || -z "$postgres_version" ]]; then
  needs_reindex=$($CONTAINER_ENGINE run --rm -v sentry-postgres:/db busybox sh -c 'if [ -f /db/PG_VERSION ] && [ ! -f /db/14-trixie-reindexed ]; then echo yes; fi')

  start_service_and_wait_ready postgres
  if [[ "$needs_reindex" == "yes" ]]; then
    echo "Re-indexing due to glibc change, this may take a while..."
    $dc exec postgres psql -U postgres -v ON_ERROR_STOP=1 -c "REINDEX DATABASE postgres;"
  fi
  $dc exec postgres sh -c 'touch "$PGDATA/14-trixie-reindexed"'
fi

echo "${_endgroup}"
