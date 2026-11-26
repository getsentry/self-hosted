#!/usr/bin/env bash

source _unit-test/_test_setup.sh
source install/dc-detect-version.sh
source install/create-docker-volumes.sh

# Set the flag to apply automatic updates
export APPLY_AUTOMATIC_CONFIG_UPDATES=1

# Here we're just gonna test to run it multiple times
# Only to make sure it doesn't break
for i in $(seq 1 5); do
  source install/bootstrap-s3-nodestore.sh
done

# Ensure that the lifecycle TTL fast path is enabled, otherwise new objects never expire
fastpath_status=$(echo "s3.bucket.lifecycle.fastpath -name=nodestore" | $dc exec -T seaweedfs weed shell)
if ! echo "$fastpath_status" | grep -q "Lifecycle TTL fast path: enabled"; then
  echo "Error: Expected the lifecycle TTL fast path to be enabled on the 'nodestore' bucket"
  exit 1
fi

report_success
