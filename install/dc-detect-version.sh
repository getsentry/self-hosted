if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  _group="::group::"
  _endgroup="::endgroup::"
else
  _group="▶ "
  _endgroup=""
fi

echo "${_group}Initializing Docker Compose ..."

if [[ "$(basename $0)" = "install.sh" ]]; then
  dc="docker compose --ansi never --env-file ${_ENV}"
else
  dc="docker compose --ansi never"
fi
proxy_args="--build-arg http_proxy=${http_proxy:-} --build-arg https_proxy=${https_proxy:-} --build-arg no_proxy=${no_proxy:-}"
dcr="$dc run --rm"
dcb="$dc build $proxy_args"
dbuild="docker build $proxy_args"

echo "${_endgroup}"
