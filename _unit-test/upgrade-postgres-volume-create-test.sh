#!/usr/bin/env bash

source _unit-test/_test_setup.sh

# Podman's `volume create` takes the name as a positional argument and has no
# --name flag, so the volume swap in upgrade-postgres.sh must not use it.

stub_dir="$_SANDBOX/stub"
mkdir -p "$stub_dir"
engine_log="$stub_dir/engine.log"
: >"$engine_log"

cat >"$stub_dir/engine" <<'STUB'
#!/usr/bin/env bash
echo "$*" >>"$ENGINE_LOG"
case "$*" in
"volume create --name"*)
  echo "Error: unknown flag: --name" >&2
  exit 125
  ;;
"volume inspect"*) exit 1 ;;
"volume ls"*) exit 0 ;;
"run"*"busybox sh -c"*) echo 14 ;;
"run"*"busybox test -f"*) exit 1 ;;
esac
exit 0
STUB
chmod +x "$stub_dir/engine"

export ENGINE_LOG="$engine_log"
export CONTAINER_ENGINE="$stub_dir/engine"
_group=""
_endgroup=""

source install/upgrade-postgres.sh >/dev/null

grep -q '^volume create sentry-postgres$' "$engine_log"
! grep -q 'volume create --name' "$engine_log"

report_success
