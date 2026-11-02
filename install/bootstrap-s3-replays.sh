# Session Replay recording segments used to go to the default filestore (`/data/files` on the
# `sentry-data` volume) because `replay.storage.backend` was not set. Sentry writes these blobs
# straight to storage, without `File` rows, and expects a bucket lifecycle policy to expire them.
# `sentry cleanup` never deletes them, so they piled up forever.
#
# This script creates a "replays" bucket on SeaweedFS with a lifecycle policy matching
# `SENTRY_EVENT_RETENTION_DAYS`, and points `replay.storage.*` at it.

# Should only run when `$COMPOSE_PROFILES` is set to `feature-complete`
if [[ "$COMPOSE_PROFILES" == "feature-complete" ]]; then
  echo "${_group}Bootstrapping seaweedfs (replays)..."

  start_service_and_wait_ready seaweedfs
  $dcx seaweedfs apk add --no-cache s3cmd
  s3cmd="$dc exec seaweedfs s3cmd"

  bucket_list=$($s3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=localhost:8333 --host-bucket='localhost:8333/%(bucket)' ls)

  if ! echo "$bucket_list" | grep -q "s3://replays"; then
    apply_config_changes_replays=0
    # Only touch if no existing replay storage config is found
    if ! grep -q "replay.storage.backend" $SENTRY_CONFIG_YML; then
      if [[ -z "${APPLY_AUTOMATIC_CONFIG_UPDATES:-}" ]]; then
        echo
        echo "We are moving Session Replay recordings from the 'sentry-data' volume to SeaweedFS,"
        echo "so they are deleted automatically once they pass the retention period."
        echo "To complete this, your sentry/config.yml file needs to be modified."
        echo
        echo "Replays recorded before this change stay on the 'sentry-data' volume and will no"
        echo "longer play back. They are not deleted automatically."
        echo "Would you like us to perform this modification automatically?"
        echo

        yn=""
        until [ ! -z "$yn" ]; do
          read -p "y or n? " yn
          case $yn in
          y | yes | 1)
            export apply_config_changes_replays=1
            echo
            echo -n "Thank you."
            ;;
          n | no | 0)
            export apply_config_changes_replays=0
            echo
            echo -n "Alright, you will need to update your sentry/config.yml file manually before running 'docker compose up'."
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

      if [[ "$APPLY_AUTOMATIC_CONFIG_UPDATES" == 1 || "$apply_config_changes_replays" == 1 ]]; then
        replays_config=$(sed -n '/^replay.storage.backend/,/s3v4"/{p}' sentry/config.example.yml)
        echo "$replays_config" >>$SENTRY_CONFIG_YML
      fi
    fi

    $s3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=localhost:8333 --host-bucket='localhost:8333/%(bucket)' mb s3://replays
  else
    echo "'replays' bucket already exists on SeaweedFS. Skipping creation."
  fi

  if [[ -z "${APPLY_AUTOMATIC_CONFIG_UPDATES:-}" || "$APPLY_AUTOMATIC_CONFIG_UPDATES" == 1 ]]; then
    lifecycle_policy=$(
      cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<LifecycleConfiguration>
    <Rule>
        <ID>Sentry-Replays-Rule</ID>
        <Status>Enabled</Status>
        <Filter></Filter>
        <Expiration>
            <Days>$SENTRY_EVENT_RETENTION_DAYS</Days>
        </Expiration>
    </Rule>
</LifecycleConfiguration>
EOF
    )

    $dc exec seaweedfs sh -c "printf '%s' '$lifecycle_policy' > /tmp/replays-lifecycle-policy.xml"
    $s3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=localhost:8333 --host-bucket='localhost:8333/%(bucket)' setlifecycle /tmp/replays-lifecycle-policy.xml s3://replays

    echo "Making sure the bucket lifecycle policy is all set up correctly..."
    $s3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=localhost:8333 --host-bucket='localhost:8333/%(bucket)' getlifecycle s3://replays
  fi
  echo "${_endgroup}"
fi
