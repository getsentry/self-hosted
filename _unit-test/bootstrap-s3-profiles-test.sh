#!/usr/bin/env bash

source _unit-test/_test_setup.sh
source install/dc-detect-version.sh
source install/create-docker-volumes.sh
source install/ensure-files-from-examples.sh
export COMPOSE_PROFILES="feature-complete"
# Set the flag to apply automatic updates
export APPLY_AUTOMATIC_CONFIG_UPDATES=1

# Here we're just gonna test to run it multiple times
# Only to make sure it doesn't break
for i in $(seq 1 5); do
  source install/bootstrap-s3-profiles.sh
done

# Ensure that the bucket has been created
if ! $dc exec seaweedfs s3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=seaweedfs:8333 --host-bucket="seaweedfs:8333/%(bucket)" ls | grep -q "s3://profiles"; then
  echo "Error: Expected the 'profiles' bucket to exist"
  exit 1
fi

# Manual cleanup, otherwise `create-docker-volumes.sh` will fail
$dc down -v --remove-orphans

report_success
