#!/usr/bin/env bash
set -ex

echo "Testing initial install"
./install.sh
./_integration-test/run.sh

echo "Ensure customizations work"
cat <<EOT > sentry/enhance-image.sh
#!/bin/bash
touch /created-by-enhance-image
apt-get update
apt-get install -y gcc libsasl2-dev python-dev libldap2-dev libssl-dev
EOT
printf "python-ldap" > sentry/requirements.txt

echo "Testing in-place upgrade"
./install.sh --minimize-downtime
./_integration-test/run.sh
./_integration-test/ensure-customizations-work.sh
