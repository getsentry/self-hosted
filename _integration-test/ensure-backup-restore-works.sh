#!/usr/bin/env bash
set -ex

source install/_lib.sh
source install/dc-detect-version.sh

echo "${_group}Test that backup/restore works..."
echo "Creating backup..."
backup_path="$(pwd)/sentry/backup"
mkdir -p $backup_path
# Docker was giving me permissioning issues when trying to create this file and write to it even after
# Instead, try creating the empty file and then give everyone write access to the backup file
touch $backup_path/backup.json
chmod 666 $backup_path/backup.json
$dcr -v $backup_path:/sentry-data/backup -T -e SENTRY_LOG_LEVEL=CRITICAL web export /sentry-data/backup/backup.json
# check to make sure there is content in the file
if [ ! -s "$backup_path/backup.json" ]; then
  echo "Backup file is empty"
  exit 1
fi

# bring postgres down and recreate the docker volume
$dc stop postgres
sleep 5
$dc rm -f -v postgres
docker volume rm sentry-postgres
export SKIP_USER_CREATION=1
source install/create-docker-volumes.sh
source install/set-up-and-migrate-database.sh
$dc up -d

# echo "Importing backup..."
$dcr --rm -T web import /etc/sentry/backup/backup.json

rm $(pwd)/sentry/backup/backup.json
