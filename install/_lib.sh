# Allow `.env` overrides using the `.env.custom` file.
# We pass this to docker compose in a couple places.
if [[ -f .env.custom ]]; then
  _ENV=.env.custom
else
  _ENV=.env
fi

# Reading .env.custom has to come first. The value won't be overriden, instead
# it would persist because of `export -p> >"$t"` later, which exports current
# environment variables to a temporary file with a `declare -x KEY=value` format.
# The new values on `.env` would be set only if they are not already set.
if [[ "$_ENV" == ".env.custom" ]]; then
  q=$(mktemp) && export -p >"$q" && set -a && . ".env.custom" && set +a && . "$q" && rm "$q" && unset q
fi

# Read .env for default values with a tip o' the hat to https://stackoverflow.com/a/59831605/90297
t=$(mktemp) && export -p >"$t" && set -a && . ".env" && set +a && . "$t" && rm "$t" && unset t

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
    # shellcheck disable=SC2001
    example="$(echo "$target" | sed 's/\.[^.]*$/.example&/')"
    if [[ ! -f "$example" ]]; then
      echo "Oops! Where did $example go? 🤨 We need it in order to create $target."
      exit
    fi
    echo "Creating $target ..."
    cp -n "$example" "$target"
  fi
}

# Check the version of $1 is greater than or equal to $2 using sort. Note: versions must be stripped of "v"
function vergte() {
  printf "%s\n%s" "$1" "$2" | sort --version-sort --check=quiet --reverse
}

export SENTRY_CONFIG_PY=sentry/sentry.conf.py
export SENTRY_CONFIG_YML=sentry/config.yml

# Increase the default 10 second SIGTERM timeout
# to ensure celery queues are properly drained
# between upgrades as task signatures may change across
# versions
export STOP_TIMEOUT=60 # seconds
