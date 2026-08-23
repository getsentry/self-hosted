#!/usr/bin/env bash

source _unit-test/_test_setup.sh
source install/dc-detect-version.sh

CERT_DIR="./certificates"
GENERATED_DIR="${CERT_DIR}/.generated"

# -----------------------------------------------------------------------
# Test 1: Feature flag is NOT set → script is a no-op, no generated dir.
# -----------------------------------------------------------------------
unset SETUP_CUSTOM_CA_CERTIFICATE
source install/setup-custom-ca-certificate.sh
test ! -d "$GENERATED_DIR"
echo "Pass: no-op when SETUP_CUSTOM_CA_CERTIFICATE is unset"

# -----------------------------------------------------------------------
# Test 2: Feature flag set but no .crt files → prints a message, no-op.
# -----------------------------------------------------------------------
export SETUP_CUSTOM_CA_CERTIFICATE=1
source install/setup-custom-ca-certificate.sh
test ! -d "$GENERATED_DIR"
echo "Pass: no-op when certificates/ has no .crt files"

# -----------------------------------------------------------------------
# Shared setup: generate a self-signed test CA certificate.
# -----------------------------------------------------------------------
openssl req -x509 -newkey rsa:2048 \
  -keyout /tmp/self-hosted-test-ca.key \
  -out "${CERT_DIR}/self-hosted-test-ca.crt" \
  -days 1 -nodes -subj "/CN=Self-Hosted Test CA DO NOT TRUST" 2>/dev/null
echo "Test certificate generated."

# -----------------------------------------------------------------------
# Test 3: Invalid .crt file → script exits non-zero (subshell to isolate).
# -----------------------------------------------------------------------
echo "not a certificate" >"${CERT_DIR}/bad.crt"
if (
  export SETUP_CUSTOM_CA_CERTIFICATE=1
  source install/setup-custom-ca-certificate.sh
) 2>/dev/null; then
  echo "Expected setup-custom-ca-certificate.sh to fail for invalid certificate input"
  exit 1
fi
rm "${CERT_DIR}/bad.crt"
echo "Pass: invalid certificate causes a non-zero exit"

# -----------------------------------------------------------------------
# Test 4: Happy path — valid cert, flag set.
#
# We override all image vars to sentry-self-hosted-jq-local (guaranteed
# present after _test_setup.sh) so the test runs without pulling large
# upstream images. The jq image has no /etc/ssl/certs, so the script uses
# an empty baseline and overlays our custom cert on top.
# -----------------------------------------------------------------------
export RELAY_IMAGE=sentry-self-hosted-jq-local
export SYMBOLICATOR_IMAGE=sentry-self-hosted-jq-local
export SNUBA_IMAGE=sentry-self-hosted-jq-local
export VROOM_IMAGE=sentry-self-hosted-jq-local
export TASKBROKER_IMAGE=sentry-self-hosted-jq-local
export UPTIME_CHECKER_IMAGE=sentry-self-hosted-jq-local

export SETUP_CUSTOM_CA_CERTIFICATE=1
source install/setup-custom-ca-certificate.sh

# The generated directory must exist.
test -d "$GENERATED_DIR"
echo "Pass: generated directory was created"

# Each service's trust store directory must exist.
for nickname in relay symbolicator snuba vroom taskbroker uptime-checker; do
  test -d "${GENERATED_DIR}/${nickname}/etc/ssl/certs"
  echo "  Pass: ${nickname} trust store directory exists"
done

# Each service's bundle must contain the custom cert's PEM block.
for nickname in relay symbolicator snuba vroom taskbroker uptime-checker; do
  bundle="${GENERATED_DIR}/${nickname}/etc/ssl/certs/ca-certificates.crt"
  test -f "$bundle"
  grep -q "BEGIN CERTIFICATE" "$bundle"
  echo "  Pass: ${nickname} ca-certificates.crt contains at least one certificate"
done

# The individual .crt file must be present in each service's cert dir.
for nickname in relay symbolicator snuba vroom taskbroker uptime-checker; do
  test -f "${GENERATED_DIR}/${nickname}/etc/ssl/certs/self-hosted-test-ca.crt"
  echo "  Pass: ${nickname} has the individual self-hosted-test-ca.crt file"
done

# openssl rehash must have created at least one hash symlink per service dir.
for nickname in relay symbolicator snuba vroom taskbroker uptime-checker; do
  cert_dir="${GENERATED_DIR}/${nickname}/etc/ssl/certs"
  hash_links=$(find "$cert_dir" -maxdepth 1 -type l | wc -l)
  test "$hash_links" -gt 0
  echo "  Pass: ${nickname} has ${hash_links} OpenSSL hash symlink(s)"
done

# -----------------------------------------------------------------------
# Test 5: Idempotency — running again produces the same result.
# -----------------------------------------------------------------------
source install/setup-custom-ca-certificate.sh

for nickname in relay symbolicator snuba vroom taskbroker uptime-checker; do
  bundle="${GENERATED_DIR}/${nickname}/etc/ssl/certs/ca-certificates.crt"
  count=$(grep -c "BEGIN CERTIFICATE" "$bundle")
  # Each run wipes and rebuilds .generated/, so exactly one copy of our cert.
  test "$count" -eq 1
  echo "  Pass: ${nickname} bundle has exactly 1 certificate after second run (no duplication)"
done
echo "Pass: script is idempotent"

report_success
