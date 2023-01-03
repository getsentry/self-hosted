echo "${_group}Building and tagging Docker images ..."

echo ""
# Build any service that provides the image sentry-self-hosted-local first,
# as it is used as the base image for sentry-cleanup-self-hosted-local.
$dcb --force-rm web
for service in "$($dc config --services)"; do
  $dcb --force-rm $service
done
echo ""
echo "Docker images built."

echo "${_endgroup}"
