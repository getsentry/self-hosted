echo "${_group}Turning things off ..."

if [[ -n "$MINIMIZE_DOWNTIME" ]]; then
  # Stop everything but relay and nginx
  $dc rm -fsv $($dc config --services | grep -v -E '^(nginx|relay)$')
else
  # Clean up old stuff and ensure nothing is working while we install/update
  if [ "$CONTAINER_ENGINE" = "docker" ]; then
    $dc down -t $STOP_TIMEOUT --rmi local --remove-orphans
  elif [ "$CONTAINER_ENGINE" = "podman" ]; then
    $dc down -t $STOP_TIMEOUT --remove-orphans
    $CONTAINER_ENGINE rmi -f $($CONTAINER_ENGINE images --quiet --filter dangling=true)
  fi
fi

echo "${_endgroup}"
