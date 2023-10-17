echo "${_group}Turning things off ..."

if [[ -n "$MINIMIZE_DOWNTIME" ]]; then
  # Stop everything but relay and nginx
  $dc rm -fsv $($dc config --services | grep -v -E '^(nginx|relay)$')
else
  # Clean up old stuff and ensure nothing is working while we install/update
  $dc down -t $STOP_TIMEOUT --rmi local --remove-orphans
  # TODO(getsentry/self-hosted#2489)
  if docker volume ls | grep -qw sentry-zookeeper; then
    docker volume rm sentry-zookeeper
  fi
fi

echo "${_endgroup}"
