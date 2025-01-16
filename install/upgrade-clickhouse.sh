echo "${_group}Upgrading Clickhouse ..."

# First check to see if user is upgrading by checking for existing clickhouse volume
if docker compose ps -a | grep -q clickhouse; then
  # Start clickhouse if it is not already running
  $dc up --wait clickhouse

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
    $dc up --wait clickhouse
    $dc down clickhouse
    $dcb --build-arg BASE_IMAGE=altinity/clickhouse-server:23.3.19.33.altinitystable clickhouse
    $dc up --wait clickhouse
  else
    echo "Detected clickhouse version $version. Skipping upgrades!"
  fi
fi
echo "${_endgroup}"
