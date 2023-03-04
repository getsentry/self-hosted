#!/usr/bin/env bash
set -ex

source install/_lib.sh
source install/dc-detect-version.sh

echo "${_group}Test that backup/restore works..."
echo "Creating backup..."
$dcr -v $(pwd)/sentry:/sentry-data/backup  --rm -T -e SENTRY_LOG_LEVEL=CRITICAL web export /sentry-data/backup/backup.json
test -f sentry/backup.json

# bring postgres down and recreate the docker volume
$dc stop postgres
sleep 5
$dc rm -f -v postgres
export SKIP_USER_CREATION=1
source install/set-up-and-migrate-database.sh
$dc up -d

echo "Importing backup..."
$dcr --rm -T web import /etc/sentry/backup.json