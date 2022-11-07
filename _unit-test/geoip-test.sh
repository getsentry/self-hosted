#!/usr/bin/env bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/_test_setup.sh"

mmdb="$PROJECT_ROOT/geoip/GeoLite2-City.mmdb"

# Starts with no mmdb, ends up with empty.
test ! -f $mmdb
source "$PROJECT_ROOT/install/geoip.sh"
diff -rub $mmdb $mmdb.empty

# Doesn't clobber existing, though.
echo GARBAGE >$mmdb
source "$PROJECT_ROOT/install/geoip.sh"
test "$(cat $mmdb)" = "GARBAGE"

report_success
