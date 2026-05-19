echo "${_group}Checking memcached backend ..."

if grep -q "\.ReconnectingMemcache" "$SENTRY_CONFIG_PY"; then
  echo "ReconnectingMemcache found in $SENTRY_CONFIG_PY, you're good."
elif grep -q "\.PyMemcacheCache" "$SENTRY_CONFIG_PY"; then
  echo ""
  echo "WARNING: PyMemcacheCache found in $SENTRY_CONFIG_PY."
  echo "PyMemcacheCache is not thread-safe under ContextPropagatingThreadPoolExecutor"
  echo "and causes ingest-monitors / ingest-occurrences to deadlock."
  echo ""
  echo "Please update your CACHES config to use ReconnectingMemcache:"
  echo ""
  echo '  CACHES = {'
  echo '      "default": {'
  echo '          "BACKEND": "sentry.cache.backends.reconnectingmemcache.ReconnectingMemcache",'
  echo '          "LOCATION": ["memcached:11211"],'
  echo '          "TIMEOUT": 3600,'
  echo '          "OPTIONS": {"ignore_exc": True, "reconnect_age": 300},'
  echo '      }'
  echo '  }'
  echo ""
  echo "See: https://github.com/getsentry/self-hosted/issues/4301"
  exit 1
elif grep -q "\.MemcachedCache" "$SENTRY_CONFIG_PY"; then
  echo "MemcachedCache found in $SENTRY_CONFIG_PY, you should switch to ReconnectingMemcache."
  echo "See:"
  echo "  https://develop.sentry.dev/self-hosted/releases/#breaking-changes"
  exit 1
else
  echo 'Your setup looks weird. Good luck.'
fi

echo "${_endgroup}"
