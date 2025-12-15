#!/usr/bin/env bash

source _unit-test/_test_setup.sh
source install/dc-detect-version.sh
source install/create-docker-volumes.sh

# Set the flag to apply automatic updates
export APPLY_AUTOMATIC_CONFIG_UPDATES=1

source install/bootstrap-s3-nodestore.sh
source install/bootstrap-s3-profiles.sh

s3_cmd="$dc exec seaweedfs s3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=seaweedfs:8333 --host-bucket=seaweedfs:8333/%(bucket)"

bucket_list=$($s3_cmd ls)
if ! echo "$bucket_list" | grep -q "s3://profiles"; then
  echo 'Error: Profiles bucket not found'
  exit 1
fi

if ! echo "$bucket_list" | grep -q "s3://nodestore"; then
  echo "Error: Nodestore bucket not found"
  exit 1
fi

# Trying to run nodestore bootstrap again should run fine even with multiple buckets
source install/bootstrap-s3-nodestore.sh

# Manual cleanup, otherwise `create-docker-volumes.sh` will fail
$dc down -v --remove-orphans

report_success
