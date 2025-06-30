if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  _group="::group::"
  _endgroup="::endgroup::"
else
  _group="▶ "
  _endgroup=""
fi

echo "${_group}Initializing Docker|Podman Compose ..."

export CONTAINER_ENGINE="docker"
if [[ "${CONTAINER_ENGINE_PODMAN:-0}" -eq 1 ]]; then
  if command -v podman &>/dev/null; then
    export CONTAINER_ENGINE="podman"
  else
    echo "FAIL: Podman is not installed on the system."
    exit 1
  fi
fi

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

if [[ "$CONTAINER_ENGINE" == "podman" ]]; then
  NO_ANSI="--no-ansi"
else
  NO_ANSI="--ansi never"
fi

if [[ "$(basename $0)" = "install.sh" ]]; then
  dc="$dc_base $NO_ANSI --env-file ${_ENV}"
else
  dc="$dc_base $NO_ANSI"
fi

proxy_args="--build-arg http_proxy=${http_proxy:-} --build-arg https_proxy=${https_proxy:-} --build-arg no_proxy=${no_proxy:-}"
if [[ "$CONTAINER_ENGINE" == "podman" ]]; then
  proxy_args_dc="--podman-build-args http_proxy=${http_proxy:-},https_proxy=${https_proxy:-},no_proxy=${no_proxy:-}"
  # Disable pod creation as these are one-off commands and creating a pod
  # prints its pod id to stdout which is messing with the output that we
  # rely on various places such as configuration generation
  dcr="$dc --profile=feature-complete --in-pod=false run --rm"
else
  proxy_args_dc=$proxy_args
  dcr="$dc run --pull=never --rm"
fi
dcb="$dc build $proxy_args"
dbuild="$CONTAINER_ENGINE build $proxy_args"
echo "$dcr"
# Utility function to handle --wait with docker and podman
function start_service_and_wait_ready() {
  local options=()
  local services=()
  local found_service=0

  for arg in "$@"; do
    if [[ $found_service -eq 0 && "$arg" == -* ]]; then
      options+=("$arg")
    else
      found_service=1
      services+=("$arg")
    fi
  done

  if [ "$CONTAINER_ENGINE" = "podman" ]; then
    $dc up --force-recreate -d "${options[@]}" "${services[@]}"
    for service in "${services[@]}"; do
      while ! $CONTAINER_ENGINE ps --filter "health=healthy" | grep "$service"; do
        sleep 2
      done
    done
  else
    $dc up --wait "${options[@]}" "${services[@]}"
  fi
}

echo "${_endgroup}"
