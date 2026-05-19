#!/usr/bin/env bash

source _unit-test/_test_setup.sh
source install/ensure-files-from-examples.sh

PYMEMCACHE_BACKEND="django.core.cache.backends.memcached.PyMemcacheCache"
RECONNECTING_MEMCACHE_BACKEND="sentry.cache.backends.reconnectingmemcache.ReconnectingMemcache"
MEMCACHED_BACKEND="django.core.cache.backends.memcached.MemcachedCache"

assert_contains() {
  local file="$1"
  local expected="$2"

  if ! grep -Fq "$expected" "$file"; then
    echo "Expected $file to contain:"
    echo "$expected"
    echo "Actual:"
    cat "$file"
    exit 1
  fi
}

assert_not_contains() {
  local file="$1"
  local unexpected="$2"

  if grep -Fq "$unexpected" "$file"; then
    echo "Expected $file not to contain:"
    echo "$unexpected"
    echo "Actual:"
    cat "$file"
    exit 1
  fi
}

write_stock_pymemcache_config() {
  cat >"$SENTRY_CONFIG_PY" <<EOF
CACHES = {
    "default": {
        "BACKEND": "$PYMEMCACHE_BACKEND",
        "LOCATION": ["memcached:11211"],
        "TIMEOUT": 3600,
        "OPTIONS": {"ignore_exc": True},
    }
}
EOF
}

write_custom_pymemcache_config() {
  cat >"$SENTRY_CONFIG_PY" <<EOF
CACHES = {
    "default": {
        "BACKEND": "$PYMEMCACHE_BACKEND",
        "LOCATION": ["memcached:11211"],
        "TIMEOUT": 3600,
        "OPTIONS": {"ignore_exc": True, "timeout": 5, "connect_timeout": 3},
    }
}
EOF
}

write_memcached_config() {
  cat >"$SENTRY_CONFIG_PY" <<EOF
CACHES = {
    "default": {
        "BACKEND": "$MEMCACHED_BACKEND",
        "LOCATION": ["memcached:11211"],
        "TIMEOUT": 3600,
        "OPTIONS": {"ignore_exc": True},
    }
}
EOF
}

echo "Test 1 (current example config)"
export APPLY_AUTOMATIC_CONFIG_UPDATES=1
source install/check-memcached-backend.sh
assert_contains "$SENTRY_CONFIG_PY" "$RECONNECTING_MEMCACHE_BACKEND"
assert_contains "$SENTRY_CONFIG_PY" '"reconnect_age": 300'

echo "Test 2 (stock PyMemcacheCache config)"
write_stock_pymemcache_config
source install/check-memcached-backend.sh
assert_contains "$SENTRY_CONFIG_PY" "$RECONNECTING_MEMCACHE_BACKEND"
assert_contains "$SENTRY_CONFIG_PY" '"OPTIONS": {"ignore_exc": True, "reconnect_age": 300}'
assert_not_contains "$SENTRY_CONFIG_PY" "$PYMEMCACHE_BACKEND"

echo "Test 3 (custom PyMemcacheCache options)"
write_custom_pymemcache_config
source install/check-memcached-backend.sh
assert_contains "$SENTRY_CONFIG_PY" "$RECONNECTING_MEMCACHE_BACKEND"
assert_contains "$SENTRY_CONFIG_PY" 'setdefault("reconnect_age", 300)'
assert_contains "$SENTRY_CONFIG_PY" 'CACHES["default"].get("OPTIONS") is None'
assert_contains "$SENTRY_CONFIG_PY" '"timeout": 5'
assert_not_contains "$SENTRY_CONFIG_PY" "$PYMEMCACHE_BACKEND"

echo "Test 4 (PyMemcacheCache with automatic updates disabled)"
write_stock_pymemcache_config
APPLY_AUTOMATIC_CONFIG_UPDATES=0 source install/check-memcached-backend.sh
assert_contains "$SENTRY_CONFIG_PY" "$PYMEMCACHE_BACKEND"

echo "Test 5 (legacy MemcachedCache config)"
write_memcached_config
if (APPLY_AUTOMATIC_CONFIG_UPDATES=1 source install/check-memcached-backend.sh); then
  echo "Expected check-memcached-backend.sh to fail on legacy MemcachedCache"
  exit 1
fi

report_success
