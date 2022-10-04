echo "${_group}Replacing TSDB ..."

replace_tsdb() {
  if (
    [[ -f "$SENTRY_CONFIG_PY" ]] &&
    ! grep -xq 'SENTRY_TSDB = "sentry.tsdb.redissnuba.RedisSnubaTSDB"' "$SENTRY_CONFIG_PY"
  ); then
    # Do NOT indent the following string as it would be reflected in the end result,
    # breaking the final config file. See getsentry/self-hosted#624.
    tsdb_settings="\
SENTRY_TSDB = \"sentry.tsdb.redissnuba.RedisSnubaTSDB\"

# Automatic switchover 90 days after $(date). Can be removed afterwards.
SENTRY_TSDB_OPTIONS = {\"switchover_timestamp\": $(date +%s) + (90 * 24 * 3600)}\
"

    if grep -q 'SENTRY_TSDB_OPTIONS = ' "$SENTRY_CONFIG_PY"; then
      echo "Not attempting automatic TSDB migration due to presence of SENTRY_TSDB_OPTIONS"
    else
      echo "Attempting to automatically migrate to new TSDB"
      # Escape newlines for sed
      tsdb_settings="${tsdb_settings//$'\n'/\\n}"
      cp "$SENTRY_CONFIG_PY" "$SENTRY_CONFIG_PY.bak"
      sed -i -e "s/^SENTRY_TSDB = .*$/${tsdb_settings}/g" "$SENTRY_CONFIG_PY" || true

      if grep -xq 'SENTRY_TSDB = "sentry.tsdb.redissnuba.RedisSnubaTSDB"' "$SENTRY_CONFIG_PY"; then
        echo "Migrated TSDB to Snuba. Old configuration file backed up to $SENTRY_CONFIG_PY.bak"
        return
      fi

      echo "Failed to automatically migrate TSDB. Reverting..."
      mv "$SENTRY_CONFIG_PY.bak" "$SENTRY_CONFIG_PY"
      echo "$SENTRY_CONFIG_PY restored from backup."
    fi

    echo "WARN: Your Sentry configuration uses a legacy data store for time-series data. Remove the options SENTRY_TSDB and SENTRY_TSDB_OPTIONS from $SENTRY_CONFIG_PY and add:"
    echo ""
    echo "$tsdb_settings"
    echo ""
    echo "For more information please refer to https://github.com/getsentry/self-hosted/pull/430"
  fi
}

replace_tsdb

echo "${_endgroup}"
