echo "${_group}Upgrading Clickhouse ..."

function wait_for_clickhouse() {
  # Wait for clickhouse
  RETRIES=30
  until $dc ps clickhouse | grep 'healthy' || [ $RETRIES -eq 0 ]; do
    echo "Waiting for clickhouse server, $((RETRIES--)) remaining attempts..."
    sleep 1
  done
}

function get_clickhouse_version() {
  $dc exec clickhouse clickhouse-client -q 'SELECT version()'
}


# First check to see if user is upgrading by checking for existing clickhouse volume
if [[ -n "$(docker volume ls -q --filter name=sentry-clickhouse)" ]]; then
  # Start clickhouse if it is not already running
  $dc up -d clickhouse

  # Wait for clickhouse
  wait_for_clickhouse

  # In order to get to 24.3, we need to first upgrade go from 21.8 -> 22.8 -> 23.3 -> 23.8 -> 24.3
  version=$(get_clickhouse_version)
  if [[ "$version" == "21.8.13.1.altinitystable" || "$version" == "21.8.12.29.altinitydev.arm" ]]; then
    $dc down clickhouse
    $dcb --build-arg BASE_IMAGE=altinity/clickhouse-server:22.8.15.25.altinitystable clickhouse
    $dc up -d clickhouse
    wait_for_clickhouse
  fi

  version=$(get_clickhouse_version)
  if [[ "$version" == "22.8.15.25.altinitystable" || "$version" == "22.8.15.25.altinitydev.arm" ]]; then
    $dc down clickhouse
    $dcb --build-arg BASE_IMAGE=altinity/clickhouse-server:23.3.19.33.altinitystable clickhouse
    $dc up -d clickhouse
    wait_for_clickhouse
  fi
  
  version=$(get_clickhouse_version)
  if [[ "$version" == "23.3.19.33.altinitystable" || "$version" == "23.3.19.33.altinitydev.arm" ]]; then
    $dc down clickhouse
    $dcb --build-arg BASE_IMAGE=altinity/clickhouse-server:23.8.11.29.altinitystable clickhouse
    $dc up -d clickhouse
    wait_for_clickhouse
  else
    echo "Detected clickhouse version $version. Skipping upgrades!"
  fi
fi
echo "${_endgroup}"
