#!/usr/bin/env bash

source _unit-test/_test_setup.sh
source install/dc-detect-version.sh
source install/create-docker-volumes.sh
source install/ensure-files-from-examples.sh
export COMPOSE_PROFILES="feature-complete"
$dc pull vroom
source install/ensure-correct-permissions-profiles-dir.sh

# Generate some random files on `sentry-vroom` volume for testing
$dc run --rm --no-deps -v sentry-vroom:/var/vroom/sentry-profiles --entrypoint /bin/bash vroom -c '
  for i in $(seq 1 1000); do
    echo This is test file $i > /var/vroom/sentry-profiles/test_file_$i.txt
  done
'

# Set the flag to apply automatic updates
export APPLY_AUTOMATIC_CONFIG_UPDATES=1

# Here we're just gonna test to run it multiple times
# Only to make sure it doesn't break
for i in $(seq 1 5); do
  source install/bootstrap-s3-profiles.sh
done

# Ensure that the files have been migrated to SeaweedFS
migrated_files_count=$($dc exec seaweedfs s3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=seaweedfs:8333 --host-bucket="seaweedfs:8333/%(bucket)" ls s3://profiles/ | wc -l)
if [[ "$migrated_files_count" -ne 1000 ]]; then
  echo "Error: Expected 1000 migrated files, but found $migrated_files_count"
  exit 1
fi

# Manual cleanup, otherwise `create-docker-volumes.sh` will fail
$dc down -v vroom seaweedfs
docker volume rm sentry-vroom sentry-seaweedfs

report_success
