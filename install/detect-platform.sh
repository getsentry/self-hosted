source install/_detect-container-engine.sh

echo "${_group}Detecting Docker platform"

# Sentry SaaS uses stock Yandex ClickHouse, but they don't provide images that
# support ARM, which is relevant especially for Apple M1 laptops, Sentry's
# standard developer environment. As a workaround, we use an altinity image
# targeting ARM.
#
# See https://github.com/getsentry/self-hosted/issues/1385#issuecomment-1101824274
#
# Images built on ARM also need to be tagged to use linux/arm64 on Apple
# silicon Macs to work around an issue where they are built for
# linux/amd64 by default due to virtualization.
# See https://github.com/docker/cli/issues/3286 for the Docker bug.

FORMAT="{{.Architecture}}"
if [[ $CONTAINER_ENGINE == "podman" ]]; then
  FORMAT="{{.Host.Arch}}"
fi

export DOCKER_ARCH=$($CONTAINER_ENGINE info --format "$FORMAT")
if [[ "$DOCKER_ARCH" = "x86_64" || "$DOCKER_ARCH" = "amd64" ]]; then
  export DOCKER_PLATFORM="linux/amd64"
elif [[ "$DOCKER_ARCH" = "aarch64" ]]; then
  export DOCKER_PLATFORM="linux/arm64"
else
  echo "FAIL: Unsupported docker architecture $DOCKER_ARCH."
  exit 1
fi
echo "Detected Docker platform is $DOCKER_PLATFORM"

echo "${_endgroup}"
