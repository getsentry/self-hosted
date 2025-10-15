echo "${_group}Turning things off ..."

# Only execute this when `seaweedfs` container is running
if [ -z "$($dc ps --quiet seaweedfs)" ]; then
  echo "SeaweedFS container is not running, skipping moving tmp data."
else
  # Only execute this when we find `*.dat` and/or `*.vif` files in `/tmp`
  if [ -n "$($dc exec seaweedfs find /tmp -maxdepth 1 \( -name "*.dat" -o -name "*.vif" \))" ]; then
    echo "Moving SeaweedFS tmp data to persistent storage..."

    $dc exec seaweedfs find /tmp -maxdepth 1 \( -name "*.dat" -o -name "*.vif" \) -exec mv -v {} /data/ \;
    $dc exec seaweedfs sh -c '[ -d /tmp/m9333 ] && mv -v /tmp/m9333 /data/ || true'
    $dc exec seaweedfs sh -c '[ -f /tmp/vol_dir.uuid ] && mv -v /tmp/vol_dir.uuid /data/ || true'

    echo "Moved SeaweedFS tmp data to persistent storage."
  fi
fi

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

exists_volume() {
  $CONTAINER_ENGINE volume inspect $1 >&/dev/null
}
remove_volume() {
  remove_command="$CONTAINER_ENGINE volume remove"
  $remove_command $1
}

if exists_volume sentry-symbolicator; then
  echo "Removed $(remove_volume sentry-symbolicator)."
fi

echo "${_endgroup}"
