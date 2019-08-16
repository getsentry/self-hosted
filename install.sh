#!/usr/bin/env bash
set -e

MIN_DOCKER_VERSION='17.05.0'
MIN_COMPOSE_VERSION='1.19.0'
MIN_RAM=3072 # MB

SENTRY_CONFIG_PY='sentry/sentry.conf.py'
SENTRY_CONFIG_YML='sentry/config.yml'
SENTRY_EXTRA_REQUIREMENTS='sentry/requirements.txt'

DID_CLEAN_UP=0
# the cleanup function will be the exit point
cleanup () {
  if [ "$DID_CLEAN_UP" -eq 1 ]; then
    return 0;
  fi
  echo "Cleaning up..."
  docker-compose down &> /dev/null
  DID_CLEAN_UP=1
}
trap cleanup ERR INT TERM

echo "Checking minimum requirements..."

DOCKER_VERSION=$(docker version --format '{{.Server.Version}}')
COMPOSE_VERSION=$(docker-compose --version | sed 's/docker-compose version \(.\{1,\}\),.*/\1/')
RAM_AVAILABLE_IN_DOCKER=$(docker run --rm busybox free -m 2>/dev/null | awk '/Mem/ {print $2}');

# Function below is inspired by https://stackoverflow.com/a/29394504/90297
function ver { printf "%03d%03d%03d%03d" $(echo "$1" | sed 's/^0*\([0-9]\+\)\.0*\([0-9]\+\)\.0*\([0-9]\+\).*/\1 \2 \3/' | head -n 3 ); }

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
    exit -1
fi

if [ $(ver $COMPOSE_VERSION) -lt $(ver $MIN_COMPOSE_VERSION) ]; then
    echo "FAIL: Expected minimum docker-compose version to be $MIN_COMPOSE_VERSION but found $COMPOSE_VERSION"
    exit -1
fi

if [ "$RAM_AVAILABLE_IN_DOCKER" -lt "$MIN_RAM" ]; then
    echo "FAIL: Expected minimum RAM available to Docker to be $MIN_RAM MB but found $RAM_AVAILABLE_IN_DOCKER MB"
    exit -1
fi

echo ""
ensure_file_from_example $SENTRY_CONFIG_PY
ensure_file_from_example $SENTRY_CONFIG_YML
ensure_file_from_example $SENTRY_EXTRA_REQUIREMENTS

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
echo "Generating secret key..."
# This is to escape the secret key to be used in sed below
SECRET_KEY=$(head /dev/urandom | tr -dc "a-z0-9@#%^&*(-_=+)" | head -c 50 | sed -e 's/[\/&]/\\&/g')
sed -i -e 's/^system.secret-key:.*$/system.secret-key: '"'$SECRET_KEY'"'/' sentry/config.yml
echo "Secret key written to sentry/config.yml"

echo ""
echo "Building and tagging Docker images..."
echo ""
docker-compose build --force-rm
echo ""
echo "Docker images built."

echo ""
echo "Setting up database..."
if [ $CI ]; then
  docker-compose run --rm web upgrade --noinput
  echo ""
  echo "Did not prompt for user creation due to non-interactive shell."
  echo "Run the following command to create one yourself (recommended):"
  echo ""
  echo "  docker-compose run --rm web createuser"
  echo ""
else
  docker-compose run --rm web upgrade
fi

echo "Boostrapping Snuba..."
docker-compose run --rm snuba-api bootstrap --force
echo ""

cleanup

echo ""
echo "----------------"
echo "You're all done! Run the following command get Sentry running:"
echo ""
echo "  docker-compose up -d"
echo ""
