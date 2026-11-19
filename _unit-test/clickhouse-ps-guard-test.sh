#!/usr/bin/env bash

source _unit-test/_test_setup.sh

# `docker compose ps` can print a lot of output. With `set -o pipefail`, a
# `grep -q` on the other end of the pipe exits at the first match, the writer
# gets SIGPIPE, and the whole pipeline is reported as failed, so the clickhouse
# steps would be skipped silently.
fake_dc="$_SANDBOX/fake-dc"
cat >"$fake_dc" <<'FAKE'
#!/usr/bin/env bash
if [ "$1" = "ps" ]; then
  echo "sentry-self-hosted-clickhouse-1 running"
  for _ in $(seq 1 20000); do
    echo "sentry-self-hosted-service-$RANDOM-1 running padding padding padding padding"
  done
fi
exit 0
FAKE
chmod +x "$fake_dc"

export dc="$fake_dc"
export CONTAINER_ENGINE=docker
export _group="" _endgroup=""

started=0
start_service_and_wait_ready() { started=1; }

source install/cleanup-clickhouse.sh >/dev/null
test "$started" -eq 1

started=0
source install/upgrade-clickhouse.sh >/dev/null
test "$started" -eq 1

report_success
