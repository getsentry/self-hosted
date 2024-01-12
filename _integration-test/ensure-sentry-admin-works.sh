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
