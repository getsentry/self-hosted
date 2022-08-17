set -euo pipefail
test "${DEBUG:-}" && set -x

# Override any user-supplied umask that could cause problems, see #1222
umask 002



# Thanks to https://unix.stackexchange.com/a/145654/108960
log_file="sentry_install_log-`date +'%Y-%m-%d_%H-%M-%S'`.txt"
exec &> >(tee -a "$log_file")

# Sentry SaaS uses stock Yandex ClickHouse, but they don't provide images that
# support ARM, which is relevant especially for Apple M1 laptops, Sentry's
# standard developer environment. As a workaround, we use an altinity image
# targeting ARM.
#
# See https://github.com/getsentry/self-hosted/issues/1385#issuecomment-1101824274
#
# Images built on ARM also need to be tagged to use linux/arm64 on Apple
# silicon Macs to work around an issue where they are built for
# linux/amd64 by default due to virtualization.
# See https://github.com/docker/cli/issues/3286 for the Docker bug.

export DOCKER_ARCH=$(docker info --format '{{.Architecture}}')

if [[ "$DOCKER_ARCH" = "x86_64" ]]; then
    export DOCKER_PLATFORM="linux/amd64"
    export CLICKHOUSE_IMAGE="yandex/clickhouse-server:20.3.9.70"
elif [[ "$DOCKER_ARCH" = "aarch64" ]]; then
    export DOCKER_PLATFORM="linux/arm64"
    export CLICKHOUSE_IMAGE="altinity/clickhouse-server:21.6.1.6734-testing-arm"
else
    echo "FAIL: Unsupported docker architecture $DOCKER_ARCH."
    exit 1
fi
echo "Detected Docker platform is $DOCKER_PLATFORM"

function send_event {
  # TODO: get sentry-cli images published
  #docker run --rm -v $(pwd):/work -e SENTRY_DSN=$SENTRY_DSN getsentry/sentry-cli send-event -m $1 --logfile $log_file
  sentry-cli send-event --no-environ -m "$1"
}

# Work from /install/ for install.sh, project root otherwise
if [[ "$(basename $0)" = "install.sh"  ]]; then
  cd "$(dirname $0)/install/"
else
  cd "$(dirname $0)"  # assume we're a test script or some such
fi

# Allow `.env` overrides using the `.env.custom` file.
# We pass this to docker compose in a couple places.
basedir="$( cd .. ; pwd -P )"  # realpath is missing on stock macOS
if [[ -f "$basedir/.env.custom" ]]; then
  _ENV="$basedir/.env.custom"
else
  _ENV="$basedir/.env"
fi

# Read .env for default values with a tip o' the hat to https://stackoverflow.com/a/59831605/90297
t=$(mktemp) && export -p > "$t" && set -a && . $_ENV && set +a && . "$t" && rm "$t" && unset t

if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  _group="::group::"
  _endgroup="::endgroup::"
else
  _group="▶ "
  _endgroup=""
fi

# A couple of the config files are referenced from other subscripts, so they
# get vars, while multiple subscripts call ensure_file_from_example.
function ensure_file_from_example {
  if [[ -f "$1" ]]; then
    echo "$1 already exists, skipped creation."
  else
    echo "Creating $1..."
    cp -n $(echo "$1" | sed 's/\.[^.]*$/.example&/') "$1"
    # sed from https://stackoverflow.com/a/25123013/90297
  fi
}
SENTRY_CONFIG_PY='../sentry/sentry.conf.py'
SENTRY_CONFIG_YML='../sentry/config.yml'

# Increase the default 10 second SIGTERM timeout
# to ensure celery queues are properly drained
# between upgrades as task signatures may change across
# versions
STOP_TIMEOUT=60 # seconds
