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

if [[ "$test_option" == "--initial-install" ]]; then
  echo "Testing initial install"
  pytest --reruns 5 _integration-test/run.py
  source _integration-test/ensure-customizations-not-present.sh
  pytest _integration-test/backup.py
elif [[ "$test_option" == "--customizations" ]]; then
  echo "Testing customizations"
  $dc up -d
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
  pytest --reruns 5 _integration-test/run.py
  source _integration-test/ensure-customizations-work.sh
  pytest _integration-test/backup.py
fi
