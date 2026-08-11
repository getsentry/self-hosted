echo "${_group}Migrating the SeaweedFS encryption key ..."

# weed mini generates /data/.mini_sse_kek before it reads the KEK left by
# weed server in the filer. Recover that filer key first so mini does not start
# with two different keys. The temporary server keeps S3 disabled, so reading
# the filer cannot trigger another KEK migration.
migration_marker="/data/.sentry-seaweedfs-kek-migrated"

migration_state=$(
  $dcr --no-deps -T --entrypoint sh seaweedfs -c \
    "if test -d /data/filerldb2 && test ! -e $migration_marker; then printf needed; else printf skipped; fi"
)

if [[ "$migration_state" == "skipped" ]]; then
  echo "No legacy SeaweedFS encryption key migration is needed."
elif [[ "$migration_state" == "needed" ]]; then
  (
    migration_container="sentry-seaweedfs-kek-migration-$$"
    trap '$CONTAINER_ENGINE rm -f "$migration_container" >/dev/null 2>&1 || true' EXIT

    $dc run -d --no-deps --name "$migration_container" --entrypoint weed seaweedfs \
      server \
      -dir=/data \
      -master=true \
      -master.port=9333 \
      -volume=false \
      -filer=true \
      -filer.port=8888 \
      -s3=false \
      -webdav=false \
      -ip.bind=0.0.0.0 >/dev/null

    filer_ready=0
    for _ in $(seq 1 60); do
      if $CONTAINER_ENGINE exec "$migration_container" sh -c \
        "HTTP_PROXY='' HTTPS_PROXY='' http_proxy='' https_proxy='' wget -q -O /dev/null http://127.0.0.1:8888/"; then
        filer_ready=1
        break
      fi
      if [[ "$($CONTAINER_ENGINE inspect --format '{{.State.Running}}' "$migration_container")" != "true" ]]; then
        break
      fi
      sleep 2
    done

    if [[ "$filer_ready" != "1" ]]; then
      echo "The temporary SeaweedFS filer did not become ready." >&2
      $CONTAINER_ENGINE logs "$migration_container" >&2
      exit 1
    fi

    $CONTAINER_ENGINE exec "$migration_container" sh -c \
      "HTTP_PROXY='' HTTPS_PROXY='' http_proxy='' https_proxy='' wget -S -O /tmp/sentry-existing-kek http://127.0.0.1:8888/etc/s3/sse_kek 2>/tmp/sentry-kek-response" || true
    status_code=$($CONTAINER_ENGINE exec "$migration_container" awk \
      '$1 ~ /^HTTP\// { code=$2 } END { print code }' /tmp/sentry-kek-response)

    if [[ "$status_code" == "404" ]]; then
      echo "No existing filer encryption key was found."
      $CONTAINER_ENGINE exec "$migration_container" touch "$migration_marker"
      exit 0 # Exit only the migration subshell; install.sh continues.
    fi
    if [[ "$status_code" != "200" ]]; then
      echo "Failed to read the existing SeaweedFS encryption key (HTTP ${status_code:-unknown})." >&2
      exit 1
    fi

    restore_xtrace=0
    if [[ "$-" == *x* ]]; then
      restore_xtrace=1
      set +x
    fi

    stored_kek=$($CONTAINER_ENGINE exec "$migration_container" cat /tmp/sentry-existing-kek)
    if [[ "$stored_kek" =~ ^[[:xdigit:]]{64}$ ]]; then
      recovered_kek=${stored_kek,,}
    else
      recovered_kek=$(
        printf '%s' "$stored_kek" | $CONTAINER_ENGINE run --rm -i \
          --entrypoint python3 \
          -v "$(pwd)/scripts/recover_seaweedfs_kek.py:/recover_seaweedfs_kek.py:ro" \
          -v sentry-seaweedfs:/data:ro \
          sentry-self-hosted-local \
          /recover_seaweedfs_kek.py /data/.mini_kek_passphrase
      )
    fi

    if [[ ! "$recovered_kek" =~ ^[[:xdigit:]]{64}$ ]]; then
      echo "The recovered SeaweedFS encryption key is invalid." >&2
      exit 1
    fi

    if current_kek=$($CONTAINER_ENGINE exec "$migration_container" sh -c 'test -f /data/.mini_sse_kek && cat /data/.mini_sse_kek'); then
      :
    else
      current_kek=""
    fi

    if [[ "$current_kek" != "$recovered_kek" ]]; then
      $CONTAINER_ENGINE exec "$migration_container" sh -c \
        'if test -f /data/.mini_sse_kek && ! test -e /data/.mini_sse_kek.pre-migration; then cp -p /data/.mini_sse_kek /data/.mini_sse_kek.pre-migration; fi'
      printf '%s' "$recovered_kek" | $CONTAINER_ENGINE exec -i "$migration_container" sh -c \
        'umask 077; cat > /data/.mini_sse_kek'
    fi

    $CONTAINER_ENGINE exec "$migration_container" touch "$migration_marker"
    unset stored_kek recovered_kek current_kek
    if [[ "$restore_xtrace" == "1" ]]; then
      set -x
    fi

    echo "The existing SeaweedFS encryption key is ready for weed mini."
  )
else
  echo "Could not determine whether the SeaweedFS encryption key migration is needed." >&2
  exit 1
fi

echo "${_endgroup}"
