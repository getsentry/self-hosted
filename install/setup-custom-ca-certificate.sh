# This will only run if the SETUP_CUSTOM_CA_CERTIFICATE environment variable is set to 1.
# Think of this as some kind of a feature flag.

setup_custom_ca_certificate_main() {

if [[ "${SETUP_CUSTOM_CA_CERTIFICATE:-}" != "1" ]]; then
  return 0
fi

echo "${_group}Setting up custom CA certificates"

# Verify that openssl is available — it is required to validate certificates and
# regenerate the OpenSSL hash-directory symlinks after overlaying custom certs.
if ! command -v openssl &>/dev/null; then
  echo "" >&2
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >&2
  echo "!! FATAL: 'openssl' binary is not found on this system.                     !!" >&2
  echo "!!                                                                          !!" >&2
  echo "!! SETUP_CUSTOM_CA_CERTIFICATE=1 requires openssl to validate and process   !!" >&2
  echo "!! your certificates. Please install openssl and re-run ./install.sh.       !!" >&2
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >&2
  return 1
fi

CERT_DIR="./certificates"
GENERATED_DIR="${CERT_DIR}/.generated"

# Collect and validate all user-provided .crt files at the top level of
# ./certificates/ (maxdepth 1 so we never read our own .generated output).
custom_certs=()
while IFS= read -r -d '' cert_file; do
  if ! openssl x509 -in "$cert_file" -noout 2>/dev/null; then
    echo "ERROR: '${cert_file}' is not a valid PEM-encoded X.509 certificate." >&2
    return 1
  fi
  custom_certs+=("$cert_file")
done < <(find "$CERT_DIR" -maxdepth 1 -name "*.crt" -print0 | sort -z)

if [[ "${#custom_certs[@]}" -eq 0 ]]; then
  echo "No .crt files found in ${CERT_DIR}/ — nothing to do."
  echo "${_endgroup}"
  return 0
fi

echo "Found ${#custom_certs[@]} custom certificate(s):"
for cert in "${custom_certs[@]}"; do
  subject=$(openssl x509 -in "$cert" -noout -subject 2>/dev/null | sed 's/^subject=//')
  echo "  $(basename "$cert"): ${subject}"
done
echo ""

# Wipe and recreate the generated directory for idempotency.
rm -rf "$GENERATED_DIR"
mkdir -p "$GENERATED_DIR"

# Pairs of service nickname and the env var that holds the image reference.
# All of these are loaded from .env (via install/_lib.sh) before this script runs.
image_nicknames=(relay symbolicator snuba vroom taskbroker uptime-checker)
image_names=(
  "${RELAY_IMAGE:-}"
  "${SYMBOLICATOR_IMAGE:-}"
  "${SNUBA_IMAGE:-}"
  "${VROOM_IMAGE:-}"
  "${TASKBROKER_IMAGE:-}"
  "${UPTIME_CHECKER_IMAGE:-}"
)

for i in "${!image_nicknames[@]}"; do
  nickname="${image_nicknames[$i]}"
  image="${image_names[$i]}"

  if [[ -z "$image" ]]; then
    echo "WARNING: No image configured for '${nickname}' — skipping."
    continue
  fi

  cert_out_dir="${GENERATED_DIR}/${nickname}/etc/ssl/certs"
  mkdir -p "$cert_out_dir"

  echo "Generating trust store for ${nickname} (${image}) ..."

  # Spin up a dormant (not running) container purely to copy /etc/ssl/certs out.
  # This preserves the exact public CA baseline that the upstream image ships with.
  tmp_container=""
  if tmp_container=$($CONTAINER_ENGINE create "$image" 2>/dev/null); then
    if ! $CONTAINER_ENGINE cp "${tmp_container}:/etc/ssl/certs/." "$cert_out_dir/" 2>/dev/null; then
      echo "  No /etc/ssl/certs found in image — using empty baseline."
    fi
    $CONTAINER_ENGINE rm "$tmp_container" >/dev/null 2>&1 || true
  else
    echo "  WARNING: Could not create a container from '${image}'. Is the image pulled?"
    echo "  Using empty baseline for ${nickname}."
  fi

  # Guarantee the bundle file exists regardless of what the image provided.
  touch "$cert_out_dir/ca-certificates.crt"

  # Overlay custom certs: place each as an individual .crt file and append its
  # PEM body to the bundle (mirrors the logic from Debian update-ca-certificates).
  for cert_file in "${custom_certs[@]}"; do
    cert_basename=$(basename "$cert_file" .crt)
    cp "$cert_file" "${cert_out_dir}/${cert_basename}.crt"
    # cat + echo guarantees a trailing newline between PEM blocks in the bundle.
    cat "$cert_file" >>"${cert_out_dir}/ca-certificates.crt"
    echo >>"${cert_out_dir}/ca-certificates.crt"
  done

  # Regenerate OpenSSL directory hash symlinks so SSL_CERT_DIR-based lookups work
  # (e.g. Go's crypto/tls, OpenSSL direct directory scan).
  openssl rehash "$cert_out_dir" 2>/dev/null || true
done

echo ""
cat <<'EOF'
========================================================================
  Custom CA trust stores have been generated under:
    certificates/.generated/

  To activate them for non-Sentry services, add the YAML snippet below
  to your docker-compose.override.yml (create the file if it does not
  exist yet).

  You only need to paste this ONCE. Afterwards, simply re-run
  ./install.sh whenever your certificates change — no Docker image
  rebuilds are needed.

------------------------------------------------------------------------
EOF

cat <<'YAML'
# Paste into docker-compose.override.yml:

x-custom-ca-relay: &ca_relay
  volumes:
    - type: bind
      read_only: true
      source: ./certificates/.generated/relay/etc/ssl/certs
      target: /etc/ssl/certs

x-custom-ca-symbolicator: &ca_symbolicator
  volumes:
    - type: bind
      read_only: true
      source: ./certificates/.generated/symbolicator/etc/ssl/certs
      target: /etc/ssl/certs

x-custom-ca-snuba: &ca_snuba
  volumes:
    - type: bind
      read_only: true
      source: ./certificates/.generated/snuba/etc/ssl/certs
      target: /etc/ssl/certs

x-custom-ca-vroom: &ca_vroom
  volumes:
    - type: bind
      read_only: true
      source: ./certificates/.generated/vroom/etc/ssl/certs
      target: /etc/ssl/certs

x-custom-ca-taskbroker: &ca_taskbroker
  volumes:
    - type: bind
      read_only: true
      source: ./certificates/.generated/taskbroker/etc/ssl/certs
      target: /etc/ssl/certs

x-custom-ca-uptime-checker: &ca_uptime_checker
  volumes:
    - type: bind
      read_only: true
      source: ./certificates/.generated/uptime-checker/etc/ssl/certs
      target: /etc/ssl/certs

services:
  relay:
    <<: *ca_relay
  symbolicator:
    <<: *ca_symbolicator
  symbolicator-cleanup:
    <<: *ca_symbolicator
  snuba-api:
    <<: *ca_snuba
  snuba-errors-consumer:
    <<: *ca_snuba
  snuba-outcomes-consumer:
    <<: *ca_snuba
  snuba-outcomes-billing-consumer:
    <<: *ca_snuba
  snuba-group-attributes-consumer:
    <<: *ca_snuba
  snuba-replacer:
    <<: *ca_snuba
  snuba-subscription-consumer-events:
    <<: *ca_snuba
  snuba-transactions-consumer:
    <<: *ca_snuba
  snuba-replays-consumer:
    <<: *ca_snuba
  snuba-issue-occurrence-consumer:
    <<: *ca_snuba
  snuba-metrics-consumer:
    <<: *ca_snuba
  snuba-subscription-consumer-transactions:
    <<: *ca_snuba
  snuba-subscription-consumer-metrics:
    <<: *ca_snuba
  snuba-subscription-consumer-generic-metrics-distributions:
    <<: *ca_snuba
  snuba-subscription-consumer-generic-metrics-sets:
    <<: *ca_snuba
  snuba-subscription-consumer-generic-metrics-counters:
    <<: *ca_snuba
  snuba-subscription-consumer-generic-metrics-gauges:
    <<: *ca_snuba
  snuba-generic-metrics-distributions-consumer:
    <<: *ca_snuba
  snuba-generic-metrics-sets-consumer:
    <<: *ca_snuba
  snuba-generic-metrics-counters-consumer:
    <<: *ca_snuba
  snuba-generic-metrics-gauges-consumer:
    <<: *ca_snuba
  snuba-profiling-profiles-consumer:
    <<: *ca_snuba
  snuba-profiling-functions-consumer:
    <<: *ca_snuba
  snuba-profiling-profile-chunks-consumer:
    <<: *ca_snuba
  snuba-eap-items-consumer:
    <<: *ca_snuba
  snuba-subscription-consumer-eap-items:
    <<: *ca_snuba
  vroom:
    <<: *ca_vroom
  taskbroker:
    <<: *ca_taskbroker
  uptime-checker:
    <<: *ca_uptime_checker
YAML

echo "========================================================================"
echo ""
echo "${_endgroup}"

return 0
}

setup_custom_ca_certificate_main
setup_custom_ca_certificate_status=$?

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  return "$setup_custom_ca_certificate_status"
fi

exit "$setup_custom_ca_certificate_status"
