echo "${_group}Building and tagging Docker images ..."

echo ""

# Use the default buildx builder to ensure locally built images
# (e.g., sentry-self-hosted-local) are accessible during the build.
# Non-default builders using the docker-container driver run in isolation
# and cannot resolve local images, causing "pull access denied" errors.
# See: https://github.com/moby/buildkit/issues/4162
if [ "$CONTAINER_ENGINE" = "docker" ]; then
  export BUILDX_BUILDER=default
fi

# Build any service that provides the image sentry-self-hosted-local first,
# as it is used as the base image for sentry-cleanup-self-hosted-local.
$dcb web
# Build each other service individually to localize potential failures better.
for service in $($dc config --services); do
  $dcb "$service"
done
echo ""
echo "Docker images built."

echo "${_endgroup}"
