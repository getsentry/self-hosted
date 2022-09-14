#!/usr/bin/env bash
set -ex

echo "Reset customizations"
rm -f sentry/enhance-image.sh
rm -f sentry/requirements.txt
export REPORT_SELF_HOSTED_ISSUES=0

echo "Testing initial install"
./install.sh
./_integration-test/run.sh
./_integration-test/ensure-customizations-not-present.sh

echo "Make customizations"
cat <<EOT > sentry/enhance-image.sh
#!/bin/bash
touch /created-by-enhance-image
apt-get update
apt-get install -y gcc libsasl2-dev python-dev libldap2-dev libssl-dev
EOT
chmod +x sentry/enhance-image.sh
printf "python-ldap" > sentry/requirements.txt

echo "Testing in-place upgrade and customizations"
./install.sh --minimize-downtime
./_integration-test/run.sh
./_integration-test/ensure-customizations-work.sh
