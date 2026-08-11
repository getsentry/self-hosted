#!/usr/bin/env bash
set -euo pipefail

old_checkout=${1:?"usage: $0 <self-hosted-25.10.0-checkout>"}
repo_root=$(cd "$(dirname "$0")/.." && pwd)
overlay="$repo_root/_integration-test/seaweedfs-upgrade/docker-compose.test.yml"
suffix="${GITHUB_RUN_ID:-$$}-${GITHUB_RUN_ATTEMPT:-0}"
volume="sentry-seaweedfs-upgrade-25-10-$suffix"
old_project="sentry-seaweedfs-25-10-old-$suffix"
current_project="sentry-seaweedfs-25-10-current-$suffix"
export SEAWEEDFS_UPGRADE_TEST_VOLUME=$volume

old_dc=(docker compose --ansi never --env-file "$old_checkout/.env" --project-name "$old_project" -f "$old_checkout/docker-compose.yml" -f "$overlay")
current_dc=(docker compose --ansi never --env-file "$repo_root/.env" --project-name "$current_project" -f "$repo_root/docker-compose.yml" -f "$overlay")

cleanup() {
  "${current_dc[@]}" down --remove-orphans >/dev/null 2>&1 || true
  "${old_dc[@]}" down --remove-orphans >/dev/null 2>&1 || true
  docker volume rm "$volume" >/dev/null 2>&1 || true
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

echo "=== Upgrade self-hosted 25.10.0 SeaweedFS 3.96 to current ==="
docker volume create "$volume" >/dev/null
"${old_dc[@]}" up -d --wait seaweedfs
"${old_dc[@]}" exec -T seaweedfs weed version | grep -F "3.96"
"${old_dc[@]}" exec -T seaweedfs apk add --no-cache s3cmd >/dev/null
"${old_dc[@]}" exec -T seaweedfs mkdir -p /data/idx/
printf 'written by self-hosted 25.10.0' | "${old_dc[@]}" exec -T seaweedfs sh -c 'cat > /tmp/before-upgrade'
"${old_dc[@]}" exec -T seaweedfs "${s3cmd[@]}" mb s3://nodestore
"${old_dc[@]}" exec -T seaweedfs "${s3cmd[@]}" put /tmp/before-upgrade s3://nodestore/before-upgrade

legacy_kek=$("${old_dc[@]}" exec -T seaweedfs sh -c \
  "HTTP_PROXY='' HTTPS_PROXY='' http_proxy='' https_proxy='' wget -qO- http://127.0.0.1:8888/etc/s3/sse_kek")
if [[ ! "$legacy_kek" =~ ^[[:xdigit:]]{64}$ ]]; then
  echo "SeaweedFS 3.96 did not create the expected legacy plaintext KEK." >&2
  "${old_dc[@]}" logs seaweedfs >&2
  exit 1
fi
"${old_dc[@]}" down --remove-orphans

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
  echo "weed mini started with a different KEK than the SeaweedFS 3.96 filer key." >&2
  exit 1
fi

"${current_dc[@]}" exec -T seaweedfs apk add --no-cache s3cmd >/dev/null
"${current_dc[@]}" exec -T seaweedfs "${s3cmd[@]}" get s3://nodestore/before-upgrade /tmp/before-upgrade
[[ "$("${current_dc[@]}" exec -T seaweedfs cat /tmp/before-upgrade)" == "written by self-hosted 25.10.0" ]]

printf 'written after the current upgrade' | "${current_dc[@]}" exec -T seaweedfs sh -c 'cat > /tmp/after-upgrade'
"${current_dc[@]}" exec -T seaweedfs "${s3cmd[@]}" put /tmp/after-upgrade s3://nodestore/after-upgrade
"${current_dc[@]}" exec -T seaweedfs "${s3cmd[@]}" get s3://nodestore/after-upgrade /tmp/after-upgrade-result
[[ "$("${current_dc[@]}" exec -T seaweedfs cat /tmp/after-upgrade-result)" == "written after the current upgrade" ]]
echo "25.10.0 upgrade asserted: current SeaweedFS preserves and writes nodestore data."
