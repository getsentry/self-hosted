#!/usr/bin/env bash
set -e

MIN_DOCKER_VERSION='17.05.0'
MIN_COMPOSE_VERSION='1.17.0'
MIN_RAM=3072 # MB
ENV_FILE='.env'

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

# Compare dot-separated strings - function below is inspired by https://stackoverflow.com/a/37939589/808368
function ver () { echo "$@" | awk -F. '{ printf("%d%03d%03d", $1,$2,$3); }'; }

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
echo "Creating volumes for persistent storage..."
echo "Created $(docker volume create --name=sentry-data)."
echo "Created $(docker volume create --name=sentry-postgres)."
echo ""

if [ -f "$ENV_FILE" ]; then
  echo "$ENV_FILE already exists, skipped creation."
else
  echo "Creating $ENV_FILE..."
  cp -n .env.example "$ENV_FILE"
fi

echo ""
echo "Building and tagging Docker images..."
echo ""
docker-compose build
echo ""
echo "Docker images built."

echo ""
echo "Generating secret key..."
# This is to escape the secret key to be used in sed below
SECRET_KEY=$(docker-compose run --rm web config generate-secret-key 2> /dev/null | tail -n1 | sed -e 's/[\/&]/\\&/g')
sed -i -e 's/^SENTRY_SECRET_KEY=.*$/SENTRY_SECRET_KEY='"$SECRET_KEY"'/' $ENV_FILE
echo "Secret key written to $ENV_FILE"

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

cleanup

echo ""
echo "----------------"
echo "You're all done! Run the following command get Sentry running:"
echo ""
echo "  docker-compose up -d"
echo ""
