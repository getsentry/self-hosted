echo "${_group}Upgrading Clickhouse ..."

function wait_for_clickhouse() {
  # Wait for clickhouse
  RETRIES=30
  until $dc ps clickhouse | grep 'healthy' || [ $RETRIES -eq 0 ]; do
    echo "Waiting for clickhouse server, $((RETRIES--)) remaining attempts..."
    sleep 1
  done
}

# First check to see if user is upgrading by checking for existing clickhouse volume
if [[ -n "$(docker volume ls -q --filter name=sentry-clickhouse)" ]]; then
  # Start clickhouse if it is not already running
  $dc up -d clickhouse

  # Wait for clickhouse
  wait_for_clickhouse

  # In order to get to 23.8, we need to first upgrade go from 20.3 -> 21.8 -> 22.8 -> 23.3 -> 23.8
  version=$($dc exec clickhouse clickhouse-client -q 'SELECT version()')
  if [[ "$version" == "20.3.9.70" ]]; then
    $dc down clickhouse
    $dcb --build-arg BASE_IMAGE=altinity/clickhouse-server:21.8.13.1.altinitystable clickhouse
    $dc up -d clickhouse
    wait_for_clickhouse
    version=$($dc exec clickhouse clickhouse-client -q 'SELECT version()')
  elif [[ "$version" == "21.8.12.29.altinitydev.arm" ]]; then
    $dc down clickhouse
    $dcb --build-arg BASE_IMAGE=altinity/clickhouse-server:21.8.12.29.altinitydev.arm clickhouse
    $dc up -d clickhouse
    wait_for_clickhouse
    version=$($dc exec clickhouse clickhouse-client -q 'SELECT version()')
  fi
  if [[ "$version" == "21.8.13.1.altinitystable" || "$version" == "21.8.12.29.altinitydev.arm" ]]; then
    $dc down clickhouse
    $dcb --build-arg BASE_IMAGE=altinity/clickhouse-server:22.8.15.25.altinitystable clickhouse
    $dc up -d clickhouse
    wait_for_clickhouse
    $dc down clickhouse
    $dcb --build-arg BASE_IMAGE=altinity/clickhouse-server:23.3.19.33.altinitystable clickhouse
    $dc up -d clickhouse
    wait_for_clickhouse
  else
    echo "Detected clickhouse version $version. Skipping upgrades!"
  fi
fi
echo "${_endgroup}"
