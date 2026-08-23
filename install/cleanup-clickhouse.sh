echo "${_group}Cleaning up ClickHouse query log tables ..."

if [ "$CONTAINER_ENGINE" = "podman" ]; then
  ps_command="$dc ps"
else
  ps_command="$dc ps -a"
fi

drop_clickhouse_system_table_if_exists() {
  local table="$1"
  local table_exists

  table_exists=$($dc exec clickhouse clickhouse-client -q "SELECT count() FROM system.tables WHERE database = 'system' AND name = '$table'")

  if [[ "$table_exists" == "1" ]]; then
    echo "Dropping system.$table ..."
    $dc exec clickhouse clickhouse-client -q "DROP TABLE system.$table"
  else
    echo "system.$table does not exist, skipping."
  fi
}

truncate_clickhouse_query_log_tables() {
  echo "Truncating system.query_log and system.query_views_log ..."
  $dc exec clickhouse clickhouse-client --multiquery -q "
SYSTEM FLUSH LOGS;
TRUNCATE TABLE IF EXISTS system.query_log;
TRUNCATE TABLE IF EXISTS system.query_views_log;
"
}

if $ps_command | grep -q clickhouse; then
  start_service_and_wait_ready clickhouse
  drop_clickhouse_system_table_if_exists query_log_0
  drop_clickhouse_system_table_if_exists query_views_log_0
  truncate_clickhouse_query_log_tables
fi

echo "${_endgroup}"
