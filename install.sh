#!/usr/bin/env bash
set -e

dc="docker-compose --no-ansi"
dcr="$dc run --rm"

# Thanks to https://unix.stackexchange.com/a/145654/108960
log_file="sentry_install_log-`date +'%Y-%m-%d_%H-%M-%S'`.txt"
exec &> >(tee -a "$log_file")

MIN_DOCKER_VERSION='17.05.0'
MIN_COMPOSE_VERSION='1.23.0'
MIN_RAM=2400 # MB

SENTRY_CONFIG_PY='sentry/sentry.conf.py'
SENTRY_CONFIG_YML='sentry/config.yml'
RELAY_CONFIG_YML='relay/config.yml'
RELAY_CREDENTIALS_JSON='relay/credentials.json'
SENTRY_EXTRA_REQUIREMENTS='sentry/requirements.txt'

DID_CLEAN_UP=0
# the cleanup function will be the exit point
cleanup () {
  if [ "$DID_CLEAN_UP" -eq 1 ]; then
    return 0;
  fi
  echo "Cleaning up..."
  $dc stop &> /dev/null
  DID_CLEAN_UP=1
}
trap cleanup ERR INT TERM

echo "Checking minimum requirements..."

DOCKER_VERSION=$(docker version --format '{{.Server.Version}}')
COMPOSE_VERSION=$($dc --version | sed 's/docker-compose version \(.\{1,\}\),.*/\1/')
RAM_AVAILABLE_IN_DOCKER=$(docker run --rm busybox free -m 2>/dev/null | awk '/Mem/ {print $2}');

# Compare dot-separated strings - function below is inspired by https://stackoverflow.com/a/37939589/808368
function ver () { echo "$@" | awk -F. '{ printf("%d%03d%03d", $1,$2,$3); }'; }

# Thanks to https://stackoverflow.com/a/25123013/90297 for the quick `sed` pattern
function ensure_file_from_example {
  if [ -f "$1" ]; then
    echo "$1 already exists, skipped creation."
  else
    echo "Creating $1..."
    cp -n $(echo "$1" | sed 's/\.[^.]*$/.example&/') "$1"
  fi
}

if [ $(ver $DOCKER_VERSION) -lt $(ver $MIN_DOCKER_VERSION) ]; then
    echo "FAIL: Expected minimum Docker version to be $MIN_DOCKER_VERSION but found $DOCKER_VERSION"
    exit 1
fi

if [ $(ver $COMPOSE_VERSION) -lt $(ver $MIN_COMPOSE_VERSION) ]; then
    echo "FAIL: Expected minimum docker-compose version to be $MIN_COMPOSE_VERSION but found $COMPOSE_VERSION"
    exit 1
fi

if [ "$RAM_AVAILABLE_IN_DOCKER" -lt "$MIN_RAM" ]; then
    echo "FAIL: Expected minimum RAM available to Docker to be $MIN_RAM MB but found $RAM_AVAILABLE_IN_DOCKER MB"
    exit 1
fi

#SSE4.2 required by Clickhouse (https://clickhouse.yandex/docs/en/operations/requirements/)
# On KVM, cpuinfo could falsely not report SSE 4.2 support, so skip the check. https://github.com/ClickHouse/ClickHouse/issues/20#issuecomment-226849297
IS_KVM=$(docker run --rm busybox grep -c 'Common KVM processor' /proc/cpuinfo || :)
if (($IS_KVM == 0)); then
  SUPPORTS_SSE42=$(docker run --rm busybox grep -c sse4_2 /proc/cpuinfo || :)
  if (($SUPPORTS_SSE42 == 0)); then
    echo "FAIL: The CPU your machine is running on does not support the SSE 4.2 instruction set, which is required for one of the services Sentry uses (Clickhouse). See https://git.io/JvLDt for more info."
    exit 1
  fi
fi

# Clean up old stuff and ensure nothing is working while we install/update
# This is for older versions of on-premise:
$dc -p onpremise down --rmi local --remove-orphans
# This is for newer versions
$dc down --rmi local --remove-orphans

echo ""
echo "Creating volumes for persistent storage..."
echo "Created $(docker volume create --name=sentry-data)."
echo "Created $(docker volume create --name=sentry-postgres)."
echo "Created $(docker volume create --name=sentry-redis)."
echo "Created $(docker volume create --name=sentry-zookeeper)."
echo "Created $(docker volume create --name=sentry-kafka)."
echo "Created $(docker volume create --name=sentry-clickhouse)."
echo "Created $(docker volume create --name=sentry-symbolicator)."

echo ""
ensure_file_from_example $SENTRY_CONFIG_PY
ensure_file_from_example $SENTRY_CONFIG_YML
ensure_file_from_example $SENTRY_EXTRA_REQUIREMENTS

if grep -xq "system.secret-key: '!!changeme!!'" $SENTRY_CONFIG_YML ; then
    echo ""
    echo "Generating secret key..."
    # This is to escape the secret key to be used in sed below
    # Note the need to set LC_ALL=C due to BSD tr and sed always trying to decode
    # whatever is passed to them. Kudos to https://stackoverflow.com/a/23584470/90297
    SECRET_KEY=$(export LC_ALL=C; head /dev/urandom | tr -dc "a-z0-9@#%^&*(-_=+)" | head -c 50 | sed -e 's/[\/&]/\\&/g')
    sed -i -e 's/^system.secret-key:.*$/system.secret-key: '"'$SECRET_KEY'"'/' $SENTRY_CONFIG_YML
    echo "Secret key written to $SENTRY_CONFIG_YML"
fi

replace_tsdb() {
    if (
        [ -f "$SENTRY_CONFIG_PY" ] &&
        ! grep -xq 'SENTRY_TSDB = "sentry.tsdb.redissnuba.RedisSnubaTSDB"' "$SENTRY_CONFIG_PY"
    ); then
        tsdb_settings="SENTRY_TSDB = \"sentry.tsdb.redissnuba.RedisSnubaTSDB\"

# Automatic switchover 90 days after $(date). Can be removed afterwards.
SENTRY_TSDB_OPTIONS = {\"switchover_timestamp\": $(date +%s) + (90 * 24 * 3600)}"

        if grep -q 'SENTRY_TSDB_OPTIONS = ' "$SENTRY_CONFIG_PY"; then
            echo "Not attempting automatic TSDB migration due to presence of SENTRY_TSDB_OPTIONS"
        else
            echo "Attempting to automatically migrate to new TSDB"
            # Escape newlines for sed
            tsdb_settings="${tsdb_settings//$'\n'/\\n}"
            cp "$SENTRY_CONFIG_PY" "$SENTRY_CONFIG_PY.bak"
            sed -i -e "s/^SENTRY_TSDB = .*$/${tsdb_settings}/g" "$SENTRY_CONFIG_PY" || true

            if grep -xq 'SENTRY_TSDB = "sentry.tsdb.redissnuba.RedisSnubaTSDB"' "$SENTRY_CONFIG_PY"; then
                echo "Migrated TSDB to Snuba. Old configuration file backed up to $SENTRY_CONFIG_PY.bak"
                return
            fi

            echo "Failed to automatically migrate TSDB. Reverting..."
            mv "$SENTRY_CONFIG_PY.bak" "$SENTRY_CONFIG_PY"
            echo "$SENTRY_CONFIG_PY restored from backup."
        fi

        echo "WARN: Your Sentry configuration uses a legacy data store for time-series data. Remove the options SENTRY_TSDB and SENTRY_TSDB_OPTIONS from $SENTRY_CONFIG_PY and add:"
        echo ""
        echo "$tsdb_settings"
        echo ""
        echo "For more information please refer to https://github.com/getsentry/onpremise/pull/430"
    fi
}

replace_tsdb

echo ""
echo "Fetching and updating Docker images..."
echo ""
# We tag locally built images with an '-onpremise-local' suffix. docker-compose pull tries to pull these too and
# shows a 404 error on the console which is confusing and unnecessary. To overcome this, we add the stderr>stdout
# redirection below and pass it through grep, ignoring all lines having this '-onpremise-local' suffix.
$dc pull -q --ignore-pull-failures 2>&1 | grep -v -- -onpremise-local || true
docker pull ${SENTRY_IMAGE:-getsentry/sentry:latest}

echo ""
echo "Building and tagging Docker images..."
echo ""
# Build the sentry onpremise image first as it is needed for the cron image
$dc build --force-rm web
$dc build --force-rm --parallel
echo ""
echo "Docker images built."

echo "Bootstrapping and migrating Snuba..."
$dcr snuba-api bootstrap --force
echo ""

# Very naively check whether there's an existing sentry-postgres volume and the PG version in it
if [[ $(docker volume ls -q --filter name=sentry-postgres) && $(docker run --rm -v sentry-postgres:/db busybox cat /db/PG_VERSION 2>/dev/null) == "9.5" ]]; then
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

echo ""
echo "Setting up database..."
if [ $CI ]; then
  $dcr web upgrade --noinput
  echo ""
  echo "Did not prompt for user creation due to non-interactive shell."
  echo "Run the following command to create one yourself (recommended):"
  echo ""
  echo "  docker-compose run --rm web createuser"
  echo ""
else
  $dcr web upgrade
fi


SENTRY_DATA_NEEDS_MIGRATION=$(docker run --rm -v sentry-data:/data alpine ash -c "[ ! -d '/data/files' ] && ls -A1x /data | wc -l || true")
if [ "$SENTRY_DATA_NEEDS_MIGRATION" ]; then
  echo "Migrating file storage..."
  # Use the web (Sentry) image so the file owners are kept as sentry:sentry
  # The `\"` escape pattern is to make this compatible w/ Git Bash on Windows. See #329.
  $dcr --entrypoint \"/bin/bash\" web -c \
    "mkdir -p /tmp/files; mv /data/* /tmp/files/; mv /tmp/files /data/files; chown -R sentry:sentry /data"
fi


if [ ! -f "$RELAY_CREDENTIALS_JSON" ]; then
  echo ""
  echo "Generating Relay credentials..."

  # We need the ugly hack below as `relay generate credentials` tries to read the config and the credentials
  # even with the `--stdout` and `--overwrite` flags and then errors out when the credentials file exists but
  # not valid JSON. We hit this case as we redirect output to the same config folder, creating an empty
  # credentials file before relay runs.
  $dcr --no-deps -v $(pwd)/$RELAY_CONFIG_YML:/tmp/config.yml relay --config /tmp credentials generate --stdout > "$RELAY_CREDENTIALS_JSON"
  echo "Relay credentials written to $RELAY_CREDENTIALS_JSON"
fi

RELAY_CREDENTIALS=$(sed -n 's/^.*"public_key"[[:space:]]*:[[:space:]]*"\([a-zA-Z0-9_-]\{1,\}\)".*$/\1/p' "$RELAY_CREDENTIALS_JSON")
if [ -z "$RELAY_CREDENTIALS" ]; then
  >&2 echo "FAIL: Cannot read credentials back from $RELAY_CREDENTIALS_JSON."
  >&2 echo "      Please ensure this file is readable and contains valid credentials."
  >&2 echo ""
  exit 1
fi

if ! grep -q "\"$RELAY_CREDENTIALS\"" "$SENTRY_CONFIG_PY"; then
  echo "SENTRY_RELAY_WHITELIST_PK = (SENTRY_RELAY_WHITELIST_PK or []) + ([\"$RELAY_CREDENTIALS\"])" >> "$SENTRY_CONFIG_PY"
  echo "Relay public key written to $SENTRY_CONFIG_PY"
  echo ""
fi

cleanup

echo ""
echo "----------------"
echo "You're all done! Run the following command to get Sentry running:"
echo ""
echo "  docker-compose up -d"
echo ""
