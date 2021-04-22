set -euo pipefail
test "${DEBUG:-}" && set -x

# Thanks to https://unix.stackexchange.com/a/145654/108960
log_file="sentry_install_log-`date +'%Y-%m-%d_%H-%M-%S'`.txt"
exec &> >(tee -a "$log_file")

# Work from /install/ for install.sh, project root otherwise
if [[ "$(basename $0)" = "install.sh" || "$(basename $0)" = "test.sh" ]]; then
  cd "$(dirname $0)/install/"
else
  cd "$(dirname $0)"  # assume we're a *-test.sh script
fi

_ENV="$(realpath ../.env)"

# Read .env for default values with a tip o' the hat to https://stackoverflow.com/a/59831605/90297
t=$(mktemp) && export -p > "$t" && set -a && . $_ENV && set +a && . "$t" && rm "$t" && unset t

if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  _group="::group::"
  _endgroup="::endgroup::"
else
  _group="▶ "
  _endgroup=""
fi

dc="docker-compose --no-ansi"
dcr="$dc run --rm"

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
