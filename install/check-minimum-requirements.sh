echo "${_group}Checking minimum requirements ..."

source "$(dirname $0)/_min-requirements.sh"

DOCKER_VERSION=$(docker version --format '{{.Server.Version}}')
# Get semantic version of Docker Compose v2
if docker compose version >/dev/null; then
  COMPOSE_VERSION=$(docker compose version --short | sed 's/v\{0,1\}\(.\{1,\}\)/\1/')
else
  # Do NOT use $dc instead of `docker-compose` below as older versions don't support certain options and fail
  COMPOSE_VERSION=$(docker-compose --version | sed 's/docker-compose version \(.\{1,\}\),.*/\1/')
fi
RAM_AVAILABLE_IN_DOCKER=$(docker run --rm busybox free -m 2>/dev/null | awk '/Mem/ {print $2}');
CPU_AVAILABLE_IN_DOCKER=$(docker run --rm busybox nproc --all);

# Compare dot-separated strings - function below is inspired by https://stackoverflow.com/a/37939589/808368
function ver () { echo "$@" | awk -F. '{ printf("%d%03d%03d", $1,$2,$3); }'; }

if [[ "$(ver $DOCKER_VERSION)" -lt "$(ver $MIN_DOCKER_VERSION)" ]]; then
  echo "FAIL: Expected minimum Docker version to be $MIN_DOCKER_VERSION but found $DOCKER_VERSION"
  exit 1
fi

if [[ "$(ver $COMPOSE_VERSION)" -lt "$(ver $MIN_COMPOSE_VERSION)" ]]; then
  echo "FAIL: Expected minimum docker-compose version to be $MIN_COMPOSE_VERSION but found $COMPOSE_VERSION"
  exit 1
fi

if [[ "$CPU_AVAILABLE_IN_DOCKER" -lt "$MIN_CPU_HARD" ]]; then
  echo "FAIL: Required minimum CPU cores available to Docker is $MIN_CPU_HARD, found $CPU_AVAILABLE_IN_DOCKER"
  exit 1
elif [[ "$CPU_AVAILABLE_IN_DOCKER" -lt "$MIN_CPU_SOFT" ]]; then
  echo "WARN: Recommended minimum CPU cores available to Docker is $MIN_CPU_SOFT, found $CPU_AVAILABLE_IN_DOCKER"
fi

if [[ "$RAM_AVAILABLE_IN_DOCKER" -lt "$MIN_RAM_HARD" ]]; then
  echo "FAIL: Required minimum RAM available to Docker is $MIN_RAM_HARD MB, found $RAM_AVAILABLE_IN_DOCKER MB"
  exit 1
elif [[ "$RAM_AVAILABLE_IN_DOCKER" -lt "$MIN_RAM_SOFT" ]]; then
  echo "WARN: Recommended minimum RAM available to Docker is $MIN_RAM_SOFT MB, found $RAM_AVAILABLE_IN_DOCKER MB"
fi

#SSE4.2 required by Clickhouse (https://clickhouse.yandex/docs/en/operations/requirements/)
# On KVM, cpuinfo could falsely not report SSE 4.2 support, so skip the check. https://github.com/ClickHouse/ClickHouse/issues/20#issuecomment-226849297
IS_KVM=$(docker run --rm busybox grep -c 'Common KVM processor' /proc/cpuinfo || :)
if [[ "$IS_KVM" -eq 0 ]]; then
  SUPPORTS_SSE42=$(docker run --rm busybox grep -c sse4_2 /proc/cpuinfo || :)
  if [[ "$SUPPORTS_SSE42" -eq 0 ]]; then
    echo "FAIL: The CPU your machine is running on does not support the SSE 4.2 instruction set, which is required for one of the services Sentry uses (Clickhouse). See https://git.io/JvLDt for more info."
    exit 1
  fi
fi

echo "${_endgroup}"
