#!/usr/bin/env bash
set -ex

echo "Reset customizations"
rm -f sentry/enhance-image.sh
rm -f sentry/requirements.txt
export REPORT_SELF_HOSTED_ISSUES=0

test_option="$1"

if [[ "$test_option" == "--initial-install" ]]; then
  echo "Testing initial install"
  _integration-test/run.sh
  _integration-test/ensure-customizations-not-present.sh
  _integration-test/ensure-backup-restore-works.sh
elif [[ "$test_option" == "--customizations" ]]; then
  echo "Testing customizations"
  source install/dc-detect-version.sh
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
  ./install.sh --minimize-downtime
  _integration-test/run.sh
  _integration-test/ensure-customizations-work.sh
  _integration-test/ensure-backup-restore-works.sh
fi
