#!/bin/bash
# This script replaces the default docker entrypoint for postgres in the
# development environment.
# Its job is to ensure postgres is properly configured to support the
# Change Data Capture pipeline (by setting access permissions and installing
# the replication plugin we use for CDC). Unfortunately the default
# Postgres image does not allow this level of configurability so we need
# to do it this way in order not to have to publish and maintain our own
# Postgres image.
#
# This then, at the end, transfers control to the default entrypoint.

set -e

prep_init_db() {
    cp /opt/sentry/init_hba.sh /docker-entrypoint-initdb.d/init_hba.sh
}

cdc_setup_hba_conf() {
    # Ensure pg-hba is properly configured to allow connections
    # to the replication slots.

    PG_HBA="$PGDATA/pg_hba.conf"
    if [ ! -f "$PG_HBA" ]; then
        echo "DB not initialized. Postgres will take care of pg_hba"
    elif [ "$(grep -c -E "^host\s+replication" "$PGDATA"/pg_hba.conf)" != 0 ]; then
        echo "Replication config already present in pg_hba. Not changing anything."
    else
        # Execute the same script we run on DB initialization
        /opt/sentry/init_hba.sh
    fi
}

bind_wal2json() {
    # Copy the file in the right place
    cp /opt/sentry/wal2json/wal2json.so `pg_config --pkglibdir`/wal2json.so
}

echo "Setting up Change Data Capture"

prep_init_db
if [ "$1" = 'postgres' ]; then
    cdc_setup_hba_conf
    bind_wal2json
fi
exec /docker-entrypoint.sh "$@"
