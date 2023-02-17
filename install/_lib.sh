set -euo pipefail
test "${DEBUG:-}" && set -x

# Override any user-supplied umask that could cause problems, see #1222
umask 002

# Thanks to https://unix.stackexchange.com/a/145654/108960
log_file=sentry_install_log-$(date +'%Y-%m-%d_%H-%M-%S').txt
exec &> >(tee -a "$log_file")

# Allow `.env` overrides using the `.env.custom` file.
# We pass this to docker compose in a couple places.
if [[ -f .env.custom ]]; then
  _ENV=.env.custom
else
  _ENV=.env
fi

# Read .env for default values with a tip o' the hat to https://stackoverflow.com/a/59831605/90297
t=$(mktemp) && export -p >"$t" && set -a && . $_ENV && set +a && . "$t" && rm "$t" && unset t

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
  target="$1"
  if [[ -f "$target" ]]; then
    echo "$target already exists, skipped creation."
  else
    # sed from https://stackoverflow.com/a/25123013/90297
    example="$(echo "$target" | sed 's/\.[^.]*$/.example&/')"
    if [[ ! -f "$example" ]]; then
      echo "Oops! Where did $example go? 🤨 We need it in order to create $target."
      exit
    fi
    echo "Creating $target ..."
    cp -n "$example" "$target"
  fi
}

SENTRY_CONFIG_PY=sentry/sentry.conf.py
SENTRY_CONFIG_YML=sentry/config.yml

# Increase the default 10 second SIGTERM timeout
# to ensure celery queues are properly drained
# between upgrades as task signatures may change across
# versions
STOP_TIMEOUT=60 # seconds
