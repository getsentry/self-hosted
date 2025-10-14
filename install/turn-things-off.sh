echo "${_group}Turning things off ..."

if ! exist_in_lockfile "move-seaweedfs-tmp-data"; then
  # Only execute this when `seaweedfs` container is running
  if ! $dc ps --quiet seaweedfs; then
    echo "SeaweedFS container is not running, skipping moving tmp data."
    return
  fi

  echo "Moving SeaweedFS tmp data to persistent storage..."
  $dc exec seaweedfs find /tmp -maxdepth 1 -name "*.dat" -exec mv -v {} /data/ \;
  $dc exec seaweedfs find /tmp -maxdepth 1 -name "*.vif" -exec mv -v {} /data/ \;
  echo "Moved SeaweedFS tmp data to persistent storage."
  add_to_lockfile "move-seaweedfs-tmp-data"
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

if ! exist_in_lockfile "remove-symbolicator-volume-distroless"; then
  if exists_volume sentry-symbolicator; then
    echo "Removed $(remove_volume sentry-symbolicator)."
    add_to_lockfile "remove-symbolicator-volume-distroless"
  fi
fi

echo "${_endgroup}"
