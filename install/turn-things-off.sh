echo "${_group}Turning things off ..."

if [[ -n "$MINIMIZE_DOWNTIME" ]]; then
  # Stop everything but relay and nginx
  $dc rm -fsv $($dc config --services | grep -v -E '^(nginx|relay)$')
else
  # Clean up old stuff and ensure nothing is working while we install/update
  if [ "$CONTAINER_ENGINE" = "podman" ]; then
    $dc down -t $STOP_TIMEOUT --remove-orphans
    dangling_images=$($CONTAINER_ENGINE images --quiet --filter dangling=true)
    if [ -n "$dangling_images" ]; then
      # Remove dangling images
      $CONTAINER_ENGINE rmi -f $dangling_images
    fi
  else
    $dc down -t $STOP_TIMEOUT --rmi local --remove-orphans
  fi
fi

echo "${_endgroup}"
