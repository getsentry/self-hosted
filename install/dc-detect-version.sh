if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  _group="::group::"
  _endgroup="::endgroup::"
else
  _group="▶ "
  _endgroup=""
fi

echo "${_group}Initializing Docker Compose ..."

# To support users that are symlinking to docker-compose
dc_base="$(docker compose version &>/dev/null && echo 'docker compose' || echo 'docker-compose')"
dc_base_standalone="$(docker-compose version &>/dev/null && echo 'docker-compose' || echo '')"

COMPOSE_VERSION=$($dc_base version --short || echo '')
if [[ -z "$COMPOSE_VERSION" ]]; then
  echo "FAIL: Docker compose is required to run self-hosted"
  exit 1
fi

STANDALONE_COMPOSE_VERSION=$($dc_base_standalone version --short &>/dev/null || echo '')
if [[ ! -z "${STANDALONE_COMPOSE_VERSION}" ]]; then
  if [[ "$(vergte ${COMPOSE_VERSION//v/} ${STANDALONE_COMPOSE_VERSION//v/})" -eq 1 ]]; then
    COMPOSE_VERSION="${STANDALONE_COMPOSE_VERSION}"
    dc_base='docker-compose'
  fi
fi

if [[ "$(basename $0)" = "install.sh" ]]; then
  dc="$dc_base --ansi never --env-file ${_ENV}"
else
  dc="$dc_base --ansi never"
fi
proxy_args="--build-arg http_proxy=${http_proxy:-} --build-arg https_proxy=${https_proxy:-} --build-arg no_proxy=${no_proxy:-}"
dcr="$dc run --pull=never --rm"
dcb="$dc build $proxy_args"
dbuild="docker build $proxy_args"

echo "${_endgroup}"
