echo "${_group}Turning things off ..."

if [[ -n "$MINIMIZE_DOWNTIME" ]]; then
  # Stop everything but relay and nginx
  $dc rm -fsv $($dc config --services | grep -v -E '^(nginx|relay)$')
else
  # Clean up old stuff and ensure nothing is working while we install/update
  # This is for older versions of on-premise:
  $dc -p onpremise down -t $STOP_TIMEOUT --rmi local --remove-orphans
  # This is for newer versions
  $dc down -t $STOP_TIMEOUT --rmi local --remove-orphans
fi

echo "${_endgroup}"
