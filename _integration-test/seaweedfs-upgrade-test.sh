#!/usr/bin/env bash
set -euo pipefail

old_checkout=${1:?"usage: $0 <self-hosted-26.6.0-checkout> <self-hosted-26.7.0-checkout>"}
broken_checkout=${2:?"usage: $0 <self-hosted-26.6.0-checkout> <self-hosted-26.7.0-checkout>"}
repo_root=$(cd "$(dirname "$0")/.." && pwd)
overlay="$repo_root/_integration-test/seaweedfs-upgrade/docker-compose.test.yml"
suffix="${GITHUB_RUN_ID:-$$}-${GITHUB_RUN_ATTEMPT:-0}"
red_volume="sentry-seaweedfs-upgrade-red-$suffix"
green_volume="sentry-seaweedfs-upgrade-green-$suffix"

old_red_dc=(docker compose --ansi never --env-file "$old_checkout/.env" --project-name "sentry-seaweedfs-old-red-$suffix" -f "$old_checkout/docker-compose.yml" -f "$overlay")
broken_dc=(docker compose --ansi never --env-file "$broken_checkout/.env" --project-name "sentry-seaweedfs-broken-$suffix" -f "$broken_checkout/docker-compose.yml" -f "$overlay")
old_green_dc=(docker compose --ansi never --env-file "$old_checkout/.env" --project-name "sentry-seaweedfs-old-green-$suffix" -f "$old_checkout/docker-compose.yml" -f "$overlay")
current_project="sentry-seaweedfs-current-$suffix"
current_dc=(docker compose --ansi never --env-file "$repo_root/.env" --project-name "$current_project" -f "$repo_root/docker-compose.yml" -f "$overlay")

cleanup() {
  SEAWEEDFS_UPGRADE_TEST_VOLUME="$green_volume" "${current_dc[@]}" down --remove-orphans >/dev/null 2>&1 || true
  SEAWEEDFS_UPGRADE_TEST_VOLUME="$green_volume" "${old_green_dc[@]}" down --remove-orphans >/dev/null 2>&1 || true
  SEAWEEDFS_UPGRADE_TEST_VOLUME="$red_volume" "${broken_dc[@]}" down --remove-orphans >/dev/null 2>&1 || true
  SEAWEEDFS_UPGRADE_TEST_VOLUME="$red_volume" "${old_red_dc[@]}" down --remove-orphans >/dev/null 2>&1 || true
  docker volume rm "$red_volume" "$green_volume" >/dev/null 2>&1 || true
}
trap cleanup EXIT

s3cmd=(
  s3cmd
  --access_key=sentry
  --secret_key=sentry
  --no-ssl
  --region=us-east-1
  --host=localhost:8333
  "--host-bucket=localhost:8333/%(bucket)"
)

seed_legacy_install() {
  local volume=$1
  shift
  local -a dc=("$@")

  export SEAWEEDFS_UPGRADE_TEST_VOLUME=$volume
  docker volume create "$volume" >/dev/null
  "${dc[@]}" up -d --wait seaweedfs
  "${dc[@]}" exec -T seaweedfs apk add --no-cache s3cmd >/dev/null
  "${dc[@]}" exec -T seaweedfs mkdir -p /data/idx/
  printf 'written before the upgrade' | "${dc[@]}" exec -T seaweedfs sh -c 'cat > /tmp/before-upgrade'
  "${dc[@]}" exec -T seaweedfs "${s3cmd[@]}" mb s3://nodestore
  "${dc[@]}" exec -T seaweedfs "${s3cmd[@]}" put /tmp/before-upgrade s3://nodestore/before-upgrade

  legacy_kek=$("${dc[@]}" exec -T seaweedfs sh -c \
    "HTTP_PROXY='' HTTPS_PROXY='' http_proxy='' https_proxy='' wget -qO- http://127.0.0.1:8888/etc/s3/sse_kek")
  if [[ ! "$legacy_kek" =~ ^[[:xdigit:]]{64}$ ]]; then
    echo "SeaweedFS 4.17 did not create the expected legacy plaintext KEK." >&2
    "${dc[@]}" logs seaweedfs >&2
    exit 1
  fi

  "${dc[@]}" down --remove-orphans
}

echo "=== RED: self-hosted 26.6.0 -> 26.7.0 must reproduce #4417 ==="
seed_legacy_install "$red_volume" "${old_red_dc[@]}"
export SEAWEEDFS_UPGRADE_TEST_VOLUME=$red_volume
"${broken_dc[@]}" pull seaweedfs
"${broken_dc[@]}" up -d --wait seaweedfs
broken_container=$("${broken_dc[@]}" ps -q seaweedfs)
[[ "$(docker inspect --format '{{.State.Health.Status}}' "$broken_container")" == "healthy" ]]

"${broken_dc[@]}" exec -T seaweedfs apk add --no-cache s3cmd >/dev/null
printf 'this write must fail' | "${broken_dc[@]}" exec -T seaweedfs sh -c 'cat > /tmp/red-write'
set +e
"${broken_dc[@]}" exec -T seaweedfs "${s3cmd[@]}" --max-retries=0 put /tmp/red-write s3://nodestore/red-write
broken_s3_result=$?
set -e
broken_logs=$("${broken_dc[@]}" logs seaweedfs 2>&1)
printf '%s\n' "$broken_logs"

if [[ "$broken_s3_result" == "0" ]]; then
  echo "Expected the unpatched 26.7.0 upgrade to reject nodestore writes." >&2
  exit 1
fi
if ! grep -Fq "s3.sse.kek does not match existing /etc/s3/sse_kek" <<<"$broken_logs"; then
  echo "The 26.7.0 upgrade failed without reproducing the expected KEK mismatch." >&2
  exit 1
fi
echo "RED asserted: 26.7.0 reports healthy, but has a KEK mismatch and nodestore writes fail."
"${broken_dc[@]}" down --remove-orphans

echo "=== GREEN: self-hosted 26.6.0 -> current PR must fix #4417 ==="
seed_legacy_install "$green_volume" "${old_green_dc[@]}"
export SEAWEEDFS_UPGRADE_TEST_VOLUME=$green_volume
grep -Fxq 'source install/migrate-seaweedfs-kek.sh' "$repo_root/install.sh"
"${current_dc[@]}" pull seaweedfs
(
  cd "$repo_root"
  export COMPOSE_FILE="$repo_root/docker-compose.yml:$overlay"
  export COMPOSE_PROJECT_NAME="$current_project"
  source install/_lib.sh
  source install/dc-detect-version.sh
  source install/migrate-seaweedfs-kek.sh
)

"${current_dc[@]}" up -d --wait seaweedfs
current_container=$("${current_dc[@]}" ps -q seaweedfs)
[[ "$(docker inspect --format '{{.State.Health.Status}}' "$current_container")" == "healthy" ]]
migrated_kek=$("${current_dc[@]}" exec -T seaweedfs cat /data/.mini_sse_kek)
[[ "$migrated_kek" == "${legacy_kek,,}" ]]
"${current_dc[@]}" exec -T seaweedfs test -e /data/.sentry-seaweedfs-kek-migrated

if "${current_dc[@]}" logs seaweedfs | grep -F "does not match existing /etc/s3/sse_kek"; then
  echo "weed mini started with a different KEK than the legacy filer key." >&2
  exit 1
fi

"${current_dc[@]}" exec -T seaweedfs apk add --no-cache s3cmd >/dev/null
"${current_dc[@]}" exec -T seaweedfs "${s3cmd[@]}" get s3://nodestore/before-upgrade /tmp/before-upgrade
[[ "$("${current_dc[@]}" exec -T seaweedfs cat /tmp/before-upgrade)" == "written before the upgrade" ]]

printf 'written after the upgrade' | "${current_dc[@]}" exec -T seaweedfs sh -c 'cat > /tmp/after-upgrade'
"${current_dc[@]}" exec -T seaweedfs "${s3cmd[@]}" put /tmp/after-upgrade s3://nodestore/after-upgrade
"${current_dc[@]}" exec -T seaweedfs "${s3cmd[@]}" get s3://nodestore/after-upgrade /tmp/after-upgrade-result
[[ "$("${current_dc[@]}" exec -T seaweedfs cat /tmp/after-upgrade-result)" == "written after the upgrade" ]]
echo "GREEN asserted: the current PR is healthy and nodestore reads and writes succeed."
