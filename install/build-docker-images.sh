echo "${_group}Building and tagging Docker images ..."

echo ""
# Build sentry-self-hosted-local first as it is needed for sentry-cleanup-self-hosted-local
$dc build --force-rm web
$dc build --force-rm
echo ""
echo "Docker images built."

echo "${_endgroup}"
