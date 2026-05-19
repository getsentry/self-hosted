echo "${_group}Checking memcached backend ..."

if grep -q "\.ReconnectingMemcache" "$SENTRY_CONFIG_PY"; then
  echo "ReconnectingMemcache found in $SENTRY_CONFIG_PY, you're good."
elif grep -q "\.PyMemcacheCache" "$SENTRY_CONFIG_PY"; then
  # PyMemcacheCache is not thread-safe under ContextPropagatingThreadPoolExecutor
  # and causes ingest-monitors / ingest-occurrences to deadlock.
  # See: https://github.com/getsentry/self-hosted/issues/4301

  apply_config_changes_memcache=0
  if [[ -z "${APPLY_AUTOMATIC_CONFIG_UPDATES:-}" ]]; then
    echo
    echo "PyMemcacheCache is no longer safe to use. The monitor consumer now runs"
    echo "check-in processing in a ContextPropagatingThreadPoolExecutor, which shares"
    echo "the non-thread-safe pymemcache client across threads, causing deadlocks."
    echo
    echo "We need to swap to ReconnectingMemcache (per-thread clients) in your config."
    echo "Do you want us to make this change automatically for you?"
    echo

    yn=""
    until [ ! -z "$yn" ]; do
      read -p "y or n? " yn
      case $yn in
      y | yes | 1)
        export apply_config_changes_memcache=1
        echo
        echo -n "Thank you."
        ;;
      n | no | 0)
        export apply_config_changes_memcache=0
        echo
        echo -n "Alright, you will need to update your sentry.conf.py file manually."
        echo " See: https://github.com/getsentry/self-hosted/issues/4301"
        ;;
      *) yn="" ;;
      esac
    done

    echo
    echo "To avoid this prompt in the future, use one of these flags:"
    echo
    echo "  --apply-automatic-config-updates"
    echo "  --no-apply-automatic-config-updates"
    echo
    echo "or set the APPLY_AUTOMATIC_CONFIG_UPDATES environment variable:"
    echo
    echo "  APPLY_AUTOMATIC_CONFIG_UPDATES=1 to apply automatic updates"
    echo "  APPLY_AUTOMATIC_CONFIG_UPDATES=0 to not apply automatic updates"
    echo
    sleep 5
  fi

  if [[ "$APPLY_AUTOMATIC_CONFIG_UPDATES" == 1 || "$apply_config_changes_memcache" == 1 ]]; then
    echo "Migrating $SENTRY_CONFIG_PY to use ReconnectingMemcache"
    sed -i 's|django\.core\.cache\.backends\.memcached\.PyMemcacheCache|sentry.cache.backends.reconnectingmemcache.ReconnectingMemcache|g' "$SENTRY_CONFIG_PY"
    # Add reconnect_age to OPTIONS if not already present
    if ! grep -q "reconnect_age" "$SENTRY_CONFIG_PY"; then
      sed -i 's/"ignore_exc": True}/"ignore_exc": True, "reconnect_age": 300}/g' "$SENTRY_CONFIG_PY"
    fi
    echo "Migrated $SENTRY_CONFIG_PY to use ReconnectingMemcache"
  fi
elif grep -q "\.MemcachedCache" "$SENTRY_CONFIG_PY"; then
  echo "MemcachedCache found in $SENTRY_CONFIG_PY, you should switch to ReconnectingMemcache."
  echo "See:"
  echo "  https://develop.sentry.dev/self-hosted/releases/#breaking-changes"
  exit 1
else
  echo 'Your setup looks weird. Good luck.'
fi

echo "${_endgroup}"
