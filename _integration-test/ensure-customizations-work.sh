#!/usr/bin/env bash
set -ex

source "$(dirname $0)/../install/_lib.sh"

source ../install/dc-detect-version.sh

echo "${_group}Ensure customizations work"
$dcr web bash -c "if [ ! -e /created-by-enhance-image ]; then exit 1; fi"
$dcr web python -c "import ldap"
echo "${_endgroup}"
