#!/usr/bin/env bash

source _unit-test/_test_setup.sh

# The recovery container reads /data/.mini_kek_passphrase, which weed writes as
# root with mode 0600. The sentry image runs as a non-root user, so the
# container has to be started as root or the read fails with PermissionError.

stub_dir="$_SANDBOX/stub"
mkdir -p "$stub_dir"
engine_log="$stub_dir/engine.log"
: >"$engine_log"

cat >"$stub_dir/engine" <<'STUB'
#!/usr/bin/env bash
echo "$*" >>"$ENGINE_LOG"
case "$1" in
run) printf '%s' "$(printf 'a%.0s' $(seq 1 64))" ;;
inspect) echo true ;;
exec)
  case "$*" in
  *"cat /tmp/sentry-existing-kek"*) printf '%s' "wrapped-not-hex" ;;
  *awk*) echo 200 ;;
  *"cat /data/.mini_sse_kek"*) exit 1 ;;
  esac
  ;;
esac
exit 0
STUB
chmod +x "$stub_dir/engine"

export ENGINE_LOG="$engine_log"
export CONTAINER_ENGINE="$stub_dir/engine"
stub_dcr() { printf needed; }
stub_dc() { "$CONTAINER_ENGINE" run "$@"; }
dcr=stub_dcr
dc=stub_dc
_group=""
_endgroup=""

source install/migrate-seaweedfs-kek.sh >/dev/null

recovery_run=$(grep -- '--entrypoint python3' "$engine_log")
test -n "$recovery_run"
[[ "$recovery_run" == *"--user 0"* ]] || [[ "$recovery_run" == *"--user root"* ]]

report_success
