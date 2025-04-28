echo "${_group}Building and tagging Docker images ..."

echo ""
# Build any service that provides the image sentry-self-hosted-local first,
# as it is used as the base image for sentry-cleanup-self-hosted-local.
dcb_force="$dcb --force-rm"
if [[ "$CONTAINER_ENGINE" == "podman" ]]; then
  dcb_force="$dcb --podman-rm-args='--force'"
fi
$dcb_force web
# Build each other service individually to localize potential failures better.
for service in $($dc config --services); do
  $dcb_force "$service"
done
echo ""
echo "Docker images built."

echo "${_endgroup}"
