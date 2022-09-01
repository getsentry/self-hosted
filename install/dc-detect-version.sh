if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  _group="::group::"
  _endgroup="::endgroup::"
else
  _group="▶ "
  _endgroup=""
fi

echo "${_group}Initializing Docker Compose ..."

function detect_compose_verson() {
  # Some environments still use `docker-compose` even for Docker Compose v2.
  dc_base="$(docker compose version &> /dev/null && echo 'docker compose' || echo 'docker-compose')"
  if [[ "$(basename $0)" = "install.sh"  ]]; then
    dc="$dc_base --ansi never --env-file ${_ENV}"
  else
    dc="$dc_base --ansi never"
  fi
  dcr="$dc run --rm"
}

detect_compose_verson

echo "${_endgroup}"
