echo "${_group}Building and tagging Docker images ..."

declare -a SERVICES=("cron"
                     "worker"
                     "ingest-consumer"
                     "post-process-forwarder-errors"
                     "post-process-forwarder-transactions"
                     "subscription-consumer-events"
                     "subscription-consumer-transactions"
                     "clickhouse"
                     "snuba-cleanup"
                     "snuba-transactions-cleanup"
                     "symbolicator-cleanup"
                     "sentry-cleanup")

echo ""
# Build any service that provides the image sentry-self-hosted-local first,
# as it is used as the base image for sentry-cleanup-self-hosted-local.
$dc build --build-arg "http_proxy=${http_proxy:-}" --build-arg "https_proxy=${https_proxy:-}" --build-arg "no_proxy=${no_proxy:-}" --force-rm web
for service in "${SERVICES[@]}"
do
   $dc build --build-arg "http_proxy=${http_proxy:-}" --build-arg "https_proxy=${https_proxy:-}" --build-arg "no_proxy=${no_proxy:-}" --force-rm $service
done
# Used in error-handling.sh for error envelope payloads
docker build -t sentry-self-hosted-jq-local --platform=$DOCKER_PLATFORM $basedir/jq
echo ""
echo "Docker images built."

echo "${_endgroup}"
