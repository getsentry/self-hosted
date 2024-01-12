#!/usr/bin/env bash
set -ex

source install/_lib.sh
source install/dc-detect-version.sh

echo "${_group}Test that backup/restore works..."
echo "Creating backup..."
# Docker was giving me permissioning issues when trying to create this file and write to it even after giving read + write access
# to group and owner. Instead, try creating the empty file and then give everyone write access to the backup file
touch $(pwd)/sentry/backup.json
chmod 666 $(pwd)/sentry/backup.json
SENTRY_DOCKER_IO_DIR=$(pwd)/sentry /bin/bash $(pwd)/sentry-admin.sh export global /sentry-admin/backup.json --no-prompt
if [ ! -s "$(pwd)/sentry/backup.json" ]; then
  echo "Backup file is empty"
  exit 1
fi

# Print backup.json contents
echo "Backup file contents:\n\n"
cat "$(pwd)/sentry/backup.json"

# Bring postgres down and recreate the docker volume
$dc stop postgres
sleep 5
$dc rm -f -v postgres
docker volume rm sentry-postgres
export SKIP_USER_CREATION=1
source install/create-docker-volumes.sh
source install/set-up-and-migrate-database.sh
$dc up -d

echo "Importing backup..."
SENTRY_DOCKER_IO_DIR=$(pwd)/sentry /bin/bash $(pwd)/sentry-admin.sh import global /sentry-admin/backup.json --no-prompt

rm $(pwd)/sentry/backup.json
