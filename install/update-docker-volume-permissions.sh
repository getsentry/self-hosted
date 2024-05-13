echo "${_group}Ensuring Kafka and Zookeeper volumes have correct permissions ..."

# Only supporting platforms on linux x86 platforms and not apple silicon. I'm assuming that folks using apple silicon are doing it for dev purposes and it's difficult
# to change permissions of docker volumes since it is run in a VM.
if [[ "$DOCKER_PLATFORM" = "linux/amd64" && -n "$(docker volume ls -q -f name=sentry-zookeeper)" && -n "$(docker volume ls -q -f name=sentry-kafka)" ]]; then
  zookeeper_data_dir="/var/lib/docker/volumes/sentry-zookeeper/_data"
  kafka_data_dir="/var/lib/docker/volumes/sentry-kafka/_data"
  zookeeper_log_data_dir="/var/lib/docker/volumes/${COMPOSE_PROJECT_NAME}_sentry-zookeeper-log/_data"
  chmod -R a+w $zookeeper_data_dir $kafka_data_dir $zookeeper_log_data_dir && returncode=$? || returncode=$?
  if [[ $returncode == "1" ]]; then
    echo "WARNING: Error when setting appropriate permissions for zookeeper, kafka, and zookeeper log docker volumes. This may corrupt your self-hosted install. See https://github.com/confluentinc/kafka-images/issues/127 for context on why this was added."
  fi
fi

echo "${_endgroup}"
