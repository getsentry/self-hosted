#!/usr/bin/env bash
set -ex

source install/_lib.sh
source install/detect-platform.sh
source install/dc-detect-version.sh
source install/error-handling.sh

echo "Reset customizations"
rm -f sentry/enhance-image.sh
rm -f sentry/requirements.txt

test_option="$1"
export MINIMIZE_DOWNTIME=0
$dc up -d

if [[ "$test_option" == "--initial-install" ]]; then
  echo "Testing initial install"
  python _integration-test/run.py
  source _integration-test/ensure-customizations-not-present.sh
  source _integration-test/ensure-backup-restore-works.sh
elif [[ "$test_option" == "--customizations" ]]; then
  echo "Testing customizations"
  echo "Making customizations"
  cat <<EOT >sentry/enhance-image.sh
#!/bin/bash
touch /created-by-enhance-image
apt-get update
apt-get install -y gcc libsasl2-dev python-dev libldap2-dev libssl-dev
EOT
  chmod +x sentry/enhance-image.sh
  printf "python-ldap" >sentry/requirements.txt

  echo "Testing in-place upgrade and customizations"
  export MINIMIZE_DOWNTIME=1
  ./install.sh
  python _integration-test/run.py
  source _integration-test/ensure-customizations-work.sh
  source _integration-test/ensure-backup-restore-works.sh
fi
