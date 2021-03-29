#!/usr/bin/env bash
set -e

if [[ -n "$MSYSTEM" ]]; then
  echo "Seems like you are using an MSYS2-based system (such as Git Bash) which is not supported. Please use WSL instead.";
  exit 1
fi

# Thanks to https://unix.stackexchange.com/a/145654/108960
log_file="sentry_install_log-`date +'%Y-%m-%d_%H-%M-%S'`.txt"
exec &> >(tee -a "$log_file")

source "$(dirname $0)/install/_lib.sh"

echo "${_group}Defining variables and helpers ..."
MIN_DOCKER_VERSION='19.03.6'
MIN_COMPOSE_VERSION='1.24.1'
MIN_RAM_HARD=3800 # MB
MIN_RAM_SOFT=7800 # MB
MIN_CPU_HARD=2
MIN_CPU_SOFT=4
echo $_endgroup

echo "${_group}Parsing command line ..."
show_help() {
  cat <<EOF
Usage: $0 [options]

Install Sentry with docker-compose.

Options:
 -h, --help             Show this message and exit.
 --no-user-prompt       Skips the initial user creation prompt (ideal for non-interactive installs).
 --minimize-downtime    EXPERIMENTAL: try to keep accepting events for as long as possible while upgrading.
                        This will disable cleanup on error, and might leave your installation in partially upgraded state.
                        This option might not reload all configuration, and is only meant for in-place upgrades.
EOF
}

SKIP_USER_PROMPT="${SKIP_USER_PROMPT:-}"
MINIMIZE_DOWNTIME="${MINIMIZE_DOWNTIME:-}"

while (( $# )); do
  case "$1" in
    -h | --help) show_help; exit;;
    --no-user-prompt) SKIP_USER_PROMPT=1;;
    --minimize-downtime) MINIMIZE_DOWNTIME=1;;
    --) ;;
    *) echo "Unexpected argument: $1. Use --help for usage information."; exit 1;;
  esac
  shift
done
echo "${_endgroup}"

echo "${_group}Setting up error handling ..."
# Courtesy of https://stackoverflow.com/a/2183063/90297
trap_with_arg() {
  func="$1" ; shift
  for sig ; do
    trap "$func $sig "'$LINENO' "$sig"
  done
}

DID_CLEAN_UP=0
# the cleanup function will be the exit point
cleanup () {
  if [[ "$DID_CLEAN_UP" -eq 1 ]]; then
    return 0;
  fi
  DID_CLEAN_UP=1

  if [[ "$1" != "EXIT" ]]; then
    echo "An error occurred, caught SIG$1 on line $2";

    if [[ -n "$MINIMIZE_DOWNTIME" ]]; then
      echo "*NOT* cleaning up, to clean your environment run \"docker-compose stop\"."
    else
      echo "Cleaning up..."
    fi
  fi

  if [[ -z "$MINIMIZE_DOWNTIME" ]]; then
    $dc stop -t $STOP_TIMEOUT &> /dev/null
  fi
}
trap_with_arg cleanup ERR INT TERM EXIT
echo "${_endgroup}"

echo "${_group}Checking minimum requirements ..."
DOCKER_VERSION=$(docker version --format '{{.Server.Version}}')
COMPOSE_VERSION=$($dc --version | sed 's/docker-compose version \(.\{1,\}\),.*/\1/')
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

source ./install/create-docker-volumes.sh
source ./install/ensure-files-from-examples.sh
source ./install/generate-secret-key.sh
source ./install/replace-tsdb.sh
source ./install/update-docker-images.sh
source ./install/build-docker-images.sh
source ./install/turn-things-off.sh
source ./install/set-up-zookeeper.sh
source ./install/bootstrap-snuba.sh
source ./install/create-kafka-topics.sh
source ./install/upgrade-postgres.sh
source ./install/set-up-and-migrate-database.sh
source ./install/migrate-file-storage.sh
source ./install/relay-credentials.sh
source ./install/geoip.sh

if [[ "$MINIMIZE_DOWNTIME" ]]; then
  source ./install/restart-carefully.sh
else
  echo ""
  echo "-----------------------------------------------------------------"
  echo ""
  echo "You're all done! Run the following command to get Sentry running:"
  echo ""
  echo "  docker-compose up -d"
  echo ""
  echo "-----------------------------------------------------------------"
  echo ""
fi
