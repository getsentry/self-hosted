echo "${_group}Building and tagging Docker images ..."

echo ""
# Build any service that provides the image sentry-self-hosted-local first,
# as it is used as the base image for sentry-cleanup-self-hosted-local.
$dcb --force-rm web
$dcb --force-rm $($dc config --services)
echo ""
echo "Docker images built."

echo "${_endgroup}"
