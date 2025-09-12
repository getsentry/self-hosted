echo "${_group}Upgrading Clickhouse ..."

# First check to see if user is upgrading by checking for existing clickhouse volume
if [ "$CONTAINER_ENGINE" = "podman" ]; then
  ps_command="$dc ps"
  build_arg="--podman-build-args"
else
  # docker compose needs to be run with the -a flag to show all containers
  ps_command="$dc ps -a"
  build_arg="--build-arg"
fi

if $ps_command | grep -q clickhouse; then
  # Start clickhouse if it is not already running
  start_service_and_wait_ready clickhouse

  # In order to get to 25.3, we need to first upgrade go from 21.8 -> 22.8 -> 23.3 -> 23.8 -> 24.8 -> 25.3
  version=$($dc exec clickhouse clickhouse-client -q 'SELECT version()')
  if [[ "$version" == "21.8.13.1.altinitystable" || "$version" == "21.8.12.29.altinitydev.arm" ]]; then
    echo "Detected clickhouse version $version"
    $dc down clickhouse

    echo "Upgrading clickhouse to 22.8"
    $dcb $build_arg BASE_IMAGE=altinity/clickhouse-server:22.8.15.25.altinitystable clickhouse
    start_service_and_wait_ready clickhouse
    $dc down clickhouse

    echo "Upgrading clickhouse to 23.3"
    $dcb $build_arg BASE_IMAGE=altinity/clickhouse-server:23.3.19.33.altinitystable clickhouse
    start_service_and_wait_ready clickhouse
    $dc down clickhouse

    echo "Upgrading clickhouse to 23.8"
    $dcb $build_arg BASE_IMAGE=altinity/clickhouse-server:23.8.11.29.altinitystable clickhouse
    start_service_and_wait_ready clickhouse
    $dc down clickhouse

    echo "Upgrading clickhouse to 24.8"
    $dcb $build_arg BASE_IMAGE=altinity/clickhouse-server:24.8.14.10459.altinitystable clickhouse
    start_service_and_wait_ready clickhouse
    $dc down clickhouse

    echo "Upgrading clickhouse to 25.3"
    $dcb $build_arg BASE_IMAGE=altinity/clickhouse-server:25.3.6.10034.altinitystable clickhouse
    start_service_and_wait_ready clickhouse
  elif [[ "$version" == "23.8.11.29.altinitystable" ]]; then
    echo "Detected clickhouse version $version"
    $dc down clickhouse

    echo "Upgrading clickhouse to 24.8"
    $dcb $build_arg BASE_IMAGE=altinity/clickhouse-server:24.8.14.10459.altinitystable clickhouse
    start_service_and_wait_ready clickhouse
    $dc down clickhouse

    echo "Upgrading clickhouse to 25.3"
    $dcb $build_arg BASE_IMAGE=altinity/clickhouse-server:25.3.6.10034.altinitystable clickhouse
    start_service_and_wait_ready clickhouse
  else
    echo "Detected clickhouse version $version. Skipping upgrades!"
  fi
fi
echo "${_endgroup}"
