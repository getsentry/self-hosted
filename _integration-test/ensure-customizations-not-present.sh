#!/usr/bin/env bash
set -ex

source "$(dirname $0)/../install/_lib.sh"

source ../install/dc-detect-version.sh

# Negated version of ensure-customizations-work.sh, make changes in sync
echo "${_group}Ensure customizations not present"
! $dcr --no-deps web bash -c "if [ ! -e /created-by-enhance-image ]; then exit 1; fi"
! $dcr --no-deps --entrypoint=/etc/sentry/entrypoint.sh sentry-cleanup bash -c "if [ ! -e /created-by-enhance-image ]; then exit 1; fi"
! $dcr --no-deps web python -c "import ldap"
! $dcr --no-deps --entrypoint=/etc/sentry/entrypoint.sh sentry-cleanup python -c "import ldap"
echo "${_endgroup}"
