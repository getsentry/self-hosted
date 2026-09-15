#!/usr/bin/env bash

source _unit-test/_test_setup.sh

mmdb=geoip/GeoLite2-City.mmdb

# Starts with no mmdb, ends up with empty.
test ! -f $mmdb
source install/geoip.sh
diff -rub $mmdb $mmdb.empty

# Doesn't clobber existing, though.
echo GARBAGE >$mmdb
source install/geoip.sh
test "$(cat $mmdb)" = "GARBAGE"

# Also works when invoked from an unrelated working directory, since the
# docs tell people to run `install/geoip.sh` directly to refresh the
# database later (e.g. from cron), not just via install.sh from the repo root.
rm -f $mmdb
sandbox_dir=$(pwd)
(cd /tmp && bash "$sandbox_dir/install/geoip.sh")
diff -rub $mmdb $mmdb.empty

report_success
