if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  _group="::group::"
  _endgroup="::endgroup::"
else
  _group="▶ "
  _endgroup=""
fi

echo "${_group}Initializing Docker|Podman Compose ..."

# To support users that are symlinking to docker-compose
dc_base="$(${CONTAINER_ENGINE} compose version --short &>/dev/null && echo "$CONTAINER_ENGINE compose" || echo '')"
dc_base_standalone="$(${CONTAINER_ENGINE}-compose version --short &>/dev/null && echo "$CONTAINER_ENGINE-compose" || echo '')"

COMPOSE_VERSION=$([ -n "$dc_base" ] && $dc_base version --short || echo '')
STANDALONE_COMPOSE_VERSION=$([ -n "$dc_base_standalone" ] && $dc_base_standalone version --short || echo '')

if [[ -z "$COMPOSE_VERSION" && -z "$STANDALONE_COMPOSE_VERSION" ]]; then
  echo "FAIL: Docker|Podman Compose is required to run self-hosted"
  exit 1
fi

if [[ -z "$COMPOSE_VERSION" ]] || [[ -n "$STANDALONE_COMPOSE_VERSION" ]] && ! vergte ${COMPOSE_VERSION//v/} ${STANDALONE_COMPOSE_VERSION//v/}; then
  COMPOSE_VERSION="${STANDALONE_COMPOSE_VERSION}"
  dc_base="$dc_base_standalone"
fi

if [[ "$CONTAINER_ENGINE" == "docker" ]]; then
  NO_ANSI="--ansi never"
elif [[ "$CONTAINER_ENGINE" == "podman" ]]; then
  NO_ANSI="--no-ansi"
fi

if [[ "$(basename $0)" = "install.sh" ]]; then
  dc="$dc_base $NO_ANSI --env-file ${_ENV}"
else
  dc="$dc_base $NO_ANSI"
fi

if [[ "$CONTAINER_ENGINE" == "docker" ]]; then
  proxy_args="--build-arg http_proxy=${http_proxy:-} --build-arg https_proxy=${https_proxy:-} --build-arg no_proxy=${no_proxy:-}"
elif [[ "$CONTAINER_ENGINE" == "podman" ]]; then
  proxy_args="--podman-build-args http_proxy=${http_proxy:-},https_proxy=${https_proxy:-},no_proxy=${no_proxy:-}"
fi
dcr="$dc run --pull=never --rm"
dcb="$dc build $proxy_args"
dbuild="$CONTAINER_ENGINE build $proxy_args"

echo "${_endgroup}"
