if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  _group="::group::"
  _endgroup="::endgroup::"
else
  _group="▶ "
  _endgroup=""
fi

echo "${_group}Initializing Docker Compose ..."

# To support users that are symlinking to docker-compose
dc_base="$(docker compose version --short &>/dev/null && echo 'docker compose' || echo '')"
dc_base_standalone="$(docker-compose version --short &>/dev/null && echo 'docker-compose' || echo '')"

COMPOSE_VERSION=$([ -n "$dc_base" ] && $dc_base version --short || echo '')
STANDALONE_COMPOSE_VERSION=$([ -n "$dc_base_standalone" ] && $dc_base_standalone version --short || echo '')

if [[ -z "$COMPOSE_VERSION" && -z "$STANDALONE_COMPOSE_VERSION" ]]; then
  echo "FAIL: Docker Compose is required to run self-hosted"
  exit 1
fi

if [[ -z "$COMPOSE_VERSION" ]] || [[ -n "$STANDALONE_COMPOSE_VERSION" ]] && ! vergte ${COMPOSE_VERSION//v/} ${STANDALONE_COMPOSE_VERSION//v/}; then
  COMPOSE_VERSION="${STANDALONE_COMPOSE_VERSION}"
  dc_base="$dc_base_standalone"
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
echo "$dcr"
echo "${_endgroup}"
