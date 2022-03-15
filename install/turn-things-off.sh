echo "${_group}Turning things off ..."

if [[ -n "$MINIMIZE_DOWNTIME" ]]; then
  # Stop everything but relay and nginx
  $dc rm -fsv $($dc config --services | grep -v -E '^(nginx|relay)$')
else
  # Clean up old stuff and ensure nothing is working while we install/update
  $dc down -t $STOP_TIMEOUT --rmi local --remove-orphans

  # Back-compat with old project name
  COMPOSE_PROJECT_NAME=sentry_onpremise \
    $dc down -t $STOP_TIMEOUT --rmi local --remove-orphans
fi

echo "${_endgroup}"
