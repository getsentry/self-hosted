echo "${_group}Fetching and updating Docker images ..."

# We tag locally built images with an '-onpremise-local' suffix. docker-compose
# pull tries to pull these too and shows a 404 error on the console which is
# confusing and unnecessary. To overcome this, we add the stderr>stdout
# redirection below and pass it through grep, ignoring all lines having this
# '-onpremise-local' suffix.
$dc pull -q --ignore-pull-failures 2>&1 | grep -v -- -onpremise-local || true

# We may not have the set image on the repo (local images) so allow fails
docker pull ${SENTRY_IMAGE} || true;

echo "${_endgroup}"
