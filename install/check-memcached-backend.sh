echo "${_group}Checking memcached backend ..."

if grep -q "\.PyMemcacheCache" "$SENTRY_CONFIG_PY"; then
  echo "PyMemcacheCache found in $SENTRY_CONFIG_PY, gonna assume you're good."
else
  if grep -q "\.MemcachedCache" "$SENTRY_CONFIG_PY"; then
    echo "MemcachedCache found in $SENTRY_CONFIG_PY, you should switch to PyMemcacheCache."
    echo "See:"
    echo "  https://develop.sentry.dev/self-hosted/releases/#breaking-changes"
    exit 1
  else
    echo 'Your setup looks weird. Good luck.'
  fi
fi

echo "${_endgroup}"
