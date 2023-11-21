#!/usr/bin/env bash
set -ex

source install/_lib.sh
source install/dc-detect-version.sh

echo "${_group}Test that sentry-admin works..."

echo "Global help documentation..."

global_help_doc=$(/bin/bash --help)
if ! echo "$global_help_doc" | grep -q "^Usage: ./sentry-admin.sh"; then
  echo "Assertion failed: Incorrect binary name in global help docs"
  exit 1
fi
if ! echo "$global_help_doc" | grep -q "SENTRY_DOCKER_IO_DIR"; then
  echo "Assertion failed: Missing SENTRY_DOCKER_IO_DIR global help doc"
  exit 1
fi

echo "Command-specific help documentation..."

command_help_doc=$(/bin/bash permissions --help)
if ! echo "$command_help_doc" | grep -q "^Usage: ./sentry-admin.sh permissions"; then
  echo "Assertion failed: Incorrect binary name in command-specific help docs"
  exit 1
fi

echo "Exports via sentry-admin..."

# Docker was giving me permissioning issues when trying to create this file and write to it even
# after giving read + write access to group and owner. Instead, try creating the empty file and then
# give everyone write access to the backup file
touch $(pwd)/sentry-admin/backup.json
chmod 666 $(pwd)/sentry-admin/backup.json

# This command uses the `sentry-admin.sh` script to try an admin command.
touch $(pwd)/sentry/admin/backup.json
chmod -R 666 $(pwd)/sentry/admin/backup.json
SENTRY_DOCKER_IO_DIR=$(pwd)/sentry-admin /bin/bash $(pwd)/sentry-admin.sh export global /sentry-admin/backup.json
if [ ! -s "$(pwd)/sentry/backup.json" ]; then
  echo "Assertion failed: Backup file is empty"
  exit 1
fi

# Print backup.json contents
echo "Backup file contents:\n\n"
cat "$(pwd)/sentry-admin/backup.json"

rm $(pwd)/sentry-admin/backup.json
