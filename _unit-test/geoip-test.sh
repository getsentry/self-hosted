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

report_success
