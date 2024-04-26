echo "${_group}Ensuring Kafka and Zookeeper volumes have correct permissions ..."

# Only supporting platforms on linux x86 platforms and not apple silicon. I'm assuming that folks using apple silicon are doing it for dev purposes and it's difficult
# to change permissions of docker volumes since it is run in a VM.
if [[ "$DOCKER_PLATFORM" = "linux/amd64" && -n "$(docker volume ls -q -f name=sentry-zookeeper)" && -n "$(docker volume ls -q -f name=sentry-kafka)" ]]; then
  chmod -R a+w /var/lib/docker/volumes/sentry-zookeeper/_data || true
  chmod -R a+w /var/lib/docker/volumes/sentry-kafka/_data || true
  chmod -R a+w /var/lib/docker/volumes/sentry-self-hosted_sentry-zookeeper-log/_data || true
fi

echo "${_endgroup}"
