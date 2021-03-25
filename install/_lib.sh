#!/usr/bin/env bash
set -euo pipefail
if [[ ! -d 'install' ]]; then echo 'Where are you?'; exit 1; fi
_ENV="$(realpath ./.env)"

define_stuff() {
  # Read .env for default values with a tip o' the hat to https://stackoverflow.com/a/59831605/90297
  t=$(mktemp) && export -p > "$t" && set -a && . $_ENV && set +a && . "$t" && rm "$t" && unset t

  if [ "${GITHUB_ACTIONS:-''}" = "true" ]; then
    _group="::group::"
    _endgroup="::endgroup::"
  else
    _group="▶ "
    _endgroup=""
  fi

  dc="docker-compose --no-ansi"
  dcr="$dc run --rm"

  function ensure_file_from_example {
    if [[ -f "$1" ]]; then
      echo "$1 already exists, skipped creation."
    else
      echo "Creating $1..."
      cp -n $(echo "$1" | sed 's/\.[^.]*$/.example&/') "$1"
      # sed from https://stackoverflow.com/a/25123013/90297
    fi
  }

  stuff_defined="yes"
}

if [ "${stuff_defined:-''}" != "" ]; then
  define_stuff
fi
