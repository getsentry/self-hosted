# The purpose of this file is to have both `sentry`-based containers and `vroom` use the same bucket for profiling.
# On pre-25.10.0, we have a `sentry-vroom` volume which stores the profiling data however, since this version,
# the behavior changed, and `vroomrs` now ingests profiles directly. Both services must share the same bucket,
# but at the time of this writing, it's not possible because the `sentry-vroom` volume has ownership set to `vroom:vroom`.
# This prevents the `sentry`-based containers from performing read/write operations on that volume.
#
# Therefore, this script should do the following:
# 1. Check if there are any files inside the `sentry-vroom` volume.
# 2. If (1) finds files, copy those files into a "profiles" bucket on SeaweedFS.
# 3. Point `filestore-profiles` and vroom to the SeaweedFS "profiles" bucket.

# Should only run when `$COMPOSE_PROFILES` is set to `feature-complete`
if [[ "$COMPOSE_PROFILES" == "feature-complete" ]]; then
  echo "${_group}Bootstrapping seaweedfs (profiles)..."

  start_service_and_wait_ready seaweedfs
  $dcx seaweedfs apk add --no-cache s3cmd
  s3cmd="$dc exec seaweedfs s3cmd"

  bucket_list=$($s3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=localhost:8333 --host-bucket='localhost:8333/%(bucket)' ls)

  if [[ $(echo "$bucket_list" | tail -1 | awk '{print $3}') != 's3://profiles' ]]; then
    apply_config_changes_profiles=0
    # Only touch if no existing profiles config is found
    if ! grep -q "filestore.profiles-backend" $SENTRY_CONFIG_YML; then
      if [[ -z "${APPLY_AUTOMATIC_CONFIG_UPDATES:-}" ]]; then
        echo
        echo "We are migrating the Profiles data directory from the 'sentry-vroom' volume to SeaweedFS."
        echo "This migration will ensure profiles ingestion works correctly with the new 'vroomrs'"
        echo "and allows both 'sentry' and 'vroom' to transition smoothly."
        echo "To complete this, your sentry/config.yml file needs to be modified."
        echo "Would you like us to perform this modification automatically?"
        echo

        yn=""
        until [ ! -z "$yn" ]; do
          read -p "y or n? " yn
          case $yn in
          y | yes | 1)
            export apply_config_changes_profiles=1
            echo
            echo -n "Thank you."
            ;;
          n | no | 0)
            export apply_config_changes_profiles=0
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

      if [[ "$APPLY_AUTOMATIC_CONFIG_UPDATES" == 1 || "$apply_config_changes_profiles" == 1 ]]; then
        profiles_config=$(sed -n '/filestore.profiles-backend/,/s3v4"/{p}' sentry/config.example.yml)
        echo "$profiles_config" >>$SENTRY_CONFIG_YML
      fi
    fi

    $s3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=localhost:8333 --host-bucket='localhost:8333/%(bucket)' mb s3://profiles

    # Check if there are files in the sentry-vroom volume
    start_service_and_wait_ready vroom
    vroom_files_count=$($dc exec vroom sh -c "find /var/vroom/sentry-profiles -type f | wc -l")
    if [[ "$vroom_files_count" -gt 0 ]]; then
      echo "Migrating $vroom_files_count files from 'sentry-vroom' volume to 'profiles' bucket on SeaweedFS..."

      # Use a temporary container to copy files from the volume to SeaweedFS

      $dcx -u root vroom sh -c 'mkdir -p /var/lib/apt/lists/partial && apt-get update && apt-get install -y --no-install-recommends s3cmd'
      $dc exec vroom sh -c 's3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=seaweedfs:8333 --host-bucket="seaweedfs:8333/%(bucket)" sync /var/vroom/sentry-profiles/ s3://profiles/'

      echo "Migration completed."
    else
      echo "No files found in 'sentry-vroom' volume. Skipping files migration."
    fi
  else
    echo "'profiles' bucket already exists on SeaweedFS. Skipping creation."
  fi

  if [[ -z "${APPLY_AUTOMATIC_CONFIG_UPDATES:-}" || "$APPLY_AUTOMATIC_CONFIG_UPDATES" == 1 ]]; then
    lifecycle_policy=$(
      cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<LifecycleConfiguration>
    <Rule>
        <ID>Sentry-Profiles-Rule</ID>
        <Status>Enabled</Status>
        <Filter></Filter>
        <Expiration>
            <Days>$SENTRY_EVENT_RETENTION_DAYS</Days>
        </Expiration>
    </Rule>
</LifecycleConfiguration>
EOF
    )

    $dc exec seaweedfs sh -c "printf '%s' '$lifecycle_policy' > /tmp/profiles-lifecycle-policy.xml"
    $s3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=localhost:8333 --host-bucket='localhost:8333/%(bucket)' setlifecycle /tmp/profiles-lifecycle-policy.xml s3://profiles

    echo "Making sure the bucket lifecycle policy is all set up correctly..."
    $s3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=localhost:8333 --host-bucket='localhost:8333/%(bucket)' getlifecycle s3://profiles
  fi
  echo "${_endgroup}"
fi
