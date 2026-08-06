#!/usr/bin/env bash

source _unit-test/_test_setup.sh
source install/ensure-files-from-examples.sh

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

assert_file_eq() {
  local file1="$1"
  local file2="$2"

  if ! diff -q "$file1" "$file2" >/dev/null 2>&1; then
    echo "Expected $file1 and $file2 to be identical."
    echo "Diff:"
    diff "$file1" "$file2" || true
    exit 1
  fi
}

# ── Test 1: Current example config, auto-apply enabled ──

echo "Test 1 (current example config, auto-apply enabled)"
cp sentry/sentry.conf.example.py "$SENTRY_CONFIG_PY"
APPLY_AUTOMATIC_CONFIG_UPDATES=1 source install/update-feature-flags.sh
assert_file_eq "$SENTRY_CONFIG_PY" sentry/sentry.conf.example.py
echo "Test 1 (current example config, auto-apply enabled) passed"

# ── Test 2: Outdated config with missing flags ──

echo "Test 2 (outdated config with missing flags)"
cp sentry/sentry.conf.example.py "$SENTRY_CONFIG_PY"
# Remove the Logs and Metrics groups (last two groups before the closing paren)
sed -i '/organizations:ourlogs-enabled/,/organizations:ourlogs-stats/d' "$SENTRY_CONFIG_PY"
sed -i '/organizations:tracemetrics-enabled/,/organizations:tracemetrics-pii-scrubbing-ui"/d' "$SENTRY_CONFIG_PY"
# Verify flags are actually gone
assert_not_contains "$SENTRY_CONFIG_PY" "organizations:ourlogs-enabled"
assert_not_contains "$SENTRY_CONFIG_PY" "organizations:tracemetrics-enabled"
APPLY_AUTOMATIC_CONFIG_UPDATES=1 source install/update-feature-flags.sh
assert_contains "$SENTRY_CONFIG_PY" "organizations:ourlogs-enabled"
assert_contains "$SENTRY_CONFIG_PY" "organizations:tracemetrics-enabled"
assert_file_eq "$SENTRY_CONFIG_PY" sentry/sentry.conf.example.py
echo "Test 2 (outdated config with missing flags) passed"

# ── Test 3: Outdated config with extra flags ──

echo "Test 3 (outdated config with extra flags)"
cp sentry/sentry.conf.example.py "$SENTRY_CONFIG_PY"
# Insert an extra flag before the closing `)` of SENTRY_FEATURES.update.
# The file contains multiple lone `)` lines, so we must target the first one
# that appears after the SENTRY_FEATURES block start.
_start_line=$(grep -n '^SENTRY_FEATURES\["projects:sample-events"\]' "$SENTRY_CONFIG_PY" | head -1 | cut -d: -f1)
_close_line=$(awk -v start="$_start_line" 'NR > start && /^\)$/ { print NR; exit }' "$SENTRY_CONFIG_PY")
sed -i "${_close_line}i\\            \"organizations:custom-extra-flag\"," "$SENTRY_CONFIG_PY"
assert_contains "$SENTRY_CONFIG_PY" "organizations:custom-extra-flag"
APPLY_AUTOMATIC_CONFIG_UPDATES=1 source install/update-feature-flags.sh
assert_not_contains "$SENTRY_CONFIG_PY" "organizations:custom-extra-flag"
assert_file_eq "$SENTRY_CONFIG_PY" sentry/sentry.conf.example.py
echo "Test 3 (outdated config with extra flags) passed"

# ── Test 4: Auto-apply disabled ──

echo "Test 4 (auto-apply disabled)"
cp sentry/sentry.conf.example.py "$SENTRY_CONFIG_PY"
# Remove a flag to simulate outdated config
sed -i '/organizations:ourlogs-enabled/d' "$SENTRY_CONFIG_PY"
_config_before=$(cat "$SENTRY_CONFIG_PY")
APPLY_AUTOMATIC_CONFIG_UPDATES=0 source install/update-feature-flags.sh
_config_after=$(cat "$SENTRY_CONFIG_PY")
if [[ "$_config_before" != "$_config_after" ]]; then
  echo "Expected config to be unchanged when APPLY_AUTOMATIC_CONFIG_UPDATES=0"
  exit 1
fi
assert_not_contains "$SENTRY_CONFIG_PY" "organizations:ourlogs-enabled"
echo "Test 4 (auto-apply disabled) passed"

# ── Test 5: Unset auto-apply ──

echo "Test 5 (unset auto-apply)"
cp sentry/sentry.conf.example.py "$SENTRY_CONFIG_PY"
# Remove a flag to simulate outdated config
sed -i '/organizations:ourlogs-enabled/d' "$SENTRY_CONFIG_PY"
_config_before=$(cat "$SENTRY_CONFIG_PY")
unset APPLY_AUTOMATIC_CONFIG_UPDATES
source install/update-feature-flags.sh
_config_after=$(cat "$SENTRY_CONFIG_PY")
if [[ "$_config_before" != "$_config_after" ]]; then
  echo "Expected config to be unchanged when APPLY_AUTOMATIC_CONFIG_UPDATES is unset"
  exit 1
fi
assert_not_contains "$SENTRY_CONFIG_PY" "organizations:ourlogs-enabled"
echo "Test 5 (unset auto-apply) passed"

report_success
