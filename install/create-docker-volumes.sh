echo "${_group}Creating volumes for persistent storage ..."

echo "Created $($CONTAINER_ENGINE volume create --name=sentry-clickhouse)."
echo "Created $($CONTAINER_ENGINE volume create --name=sentry-data)."
echo "Created $($CONTAINER_ENGINE volume create --name=sentry-kafka)."
echo "Created $($CONTAINER_ENGINE volume create --name=sentry-postgres)."
echo "Created $($CONTAINER_ENGINE volume create --name=sentry-redis)."
echo "Created $($CONTAINER_ENGINE volume create --name=sentry-symbolicator)."

echo "${_endgroup}"
