if [[ "$MINIMIZE_DOWNTIME" ]]; then
  echo "${_group}Waiting for Sentry to start ..."

  # Start the whole setup, except nginx and relay.
  start_service_and_wait_ready --remove-orphans $($dc config --services | grep -v -E '^(nginx|relay)$')
  $dc restart relay
  $dc exec -T nginx nginx -s reload

  $CONTAINER_ENGINE run --rm --network="${COMPOSE_PROJECT_NAME}_default" alpine ash \
    -c 'while [[ "$(wget -T 1 -q -O- http://web:9000/_health/)" != "ok" ]]; do sleep 0.5; done'

  # Make sure everything is up. This should only touch relay and nginx
  start_service_and_wait_ready $($dc config --services)

  echo "${_endgroup}"
else
  echo ""
  echo "-----------------------------------------------------------------"
  echo ""
  echo "You're all done! Run the following command to get Sentry running:"
  echo ""
  if [[ "${_ENV}" =~ ".env.custom" ]]; then
    echo "  $dc_base --env-file .env --env-file ${_ENV} up --wait"
  else
    if [[ "$CONTAINER_ENGINE" == "podman" ]]; then
      if [[ "$COMPOSE_PROFILES" == "feature-complete" ]]; then
        echo "  $dc_base --profile=feature-complete up --force-recreate -d"
      else
        echo "  $dc_base up --force-recreate -d"
      fi
    else
      echo "  $dc_base up --wait"
    fi
  fi
  echo ""
  echo "-----------------------------------------------------------------"
  echo ""
fi
