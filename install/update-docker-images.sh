echo "${_group}Fetching and updating $CONTAINER_ENGINE images ..."

if [ "$CONTAINER_ENGINE" = "podman" ]; then
  # podman compose doesn't have the --ignore-pull-failures option, so can just
  # run the command normally
  $dc --profile feature-complete pull || true
else
  # We tag locally built images with a '-self-hosted-local' suffix. `docker
  # compose pull` tries to pull these too and shows a 404 error on the console
  # which is confusing and unnecessary. To overcome this, we add the
  # stderr>stdout redirection below and pass it through grep, ignoring all lines
  # having this '-onpremise-local' suffix.

  $dc pull --ignore-pull-failures 2>&1 | grep -v -- -self-hosted-local || true
fi

# We may not have the set image on the repo (local images) so allow fails
$CONTAINER_ENGINE pull ${SENTRY_IMAGE} || true

echo "${_endgroup}"
