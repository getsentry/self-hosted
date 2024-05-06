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

if ! command -v docker &>/dev/null; then
  echo "FAIL: Could not find a \`docker\` binary on this system. Are you sure it's installed?"
  exit 1
fi

export DOCKER_ARCH=$(docker info --format '{{.Architecture}}')
if [[ "$DOCKER_ARCH" = "x86_64" ]]; then
  export DOCKER_PLATFORM="linux/amd64"
elif [[ "$DOCKER_ARCH" = "aarch64" ]]; then
  export DOCKER_PLATFORM="linux/arm64"
else
  echo "FAIL: Unsupported docker architecture $DOCKER_ARCH."
  exit 1
fi
echo "Detected Docker platform is $DOCKER_PLATFORM"

echo "${_endgroup}"
