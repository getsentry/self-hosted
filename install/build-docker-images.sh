echo "${_group}Building and tagging Docker images ..."

echo ""
# Build any service that provides the image sentry-self-hosted-local first,
# as it is used as the base image for sentry-cleanup-self-hosted-local.
$dc build --build-arg "http_proxy=${http_proxy:-}" --build-arg "https_proxy=${https_proxy:-}" --build-arg "no_proxy=${no_proxy:-}" --force-rm web
$dc build --build-arg "http_proxy=${http_proxy:-}" --build-arg "https_proxy=${https_proxy:-}" --build-arg "no_proxy=${no_proxy:-}" --force-rm
echo ""
echo "Docker images built."

echo "${_endgroup}"
