echo "${_group}Ensuring Kafka and Zookeeper volumes have correct permissions ..."

# Only supporting platforms on linux x86 platforms and not apple silicon. I'm assuming that folks using apple silicon are doing it for dev purposes and it's difficult
# to change permissions of docker volumes since it is run in a VM.
if [[ -n "$(docker volume ls -q -f name=sentry-zookeeper)" && -n "$(docker volume ls -q -f name=sentry-kafka)" ]]; then
  docker run --rm -v "sentry-zookeeper:/sentry-zookeeper-data" -v "sentry-kafka:/sentry-kafka-data" -v "${COMPOSE_PROJECT_NAME}_sentry-zookeeper-log:/sentry-zookeeper-log-data" busybox chmod -R a+w /sentry-zookeeper-data /sentry-kafka-data /sentry-zookeeper-log-data
fi

echo "${_endgroup}"
