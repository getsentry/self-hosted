set -euo pipefail
test ${DEBUG:-''} && set -x
cd "$(dirname $0)"
rm -rf /tmp/sentry-onpremise-test-sandbox.*
_SANDBOX="$(mktemp -d /tmp/sentry-onpremise-test-sandbox.XXX)"

teardown() {
  test ${DEBUG:-''} || rm -rf "$_SANDBOX"
}

setup() {
  # Clone the local repo into a temp dir, and propagate local changes.

  cd ..
  git clone --depth=1 "file://$(pwd)" "$_SANDBOX"

  git status --porcelain | while read line; do
    local operation="$(cut -f1 -d' ' <(echo $line))"
    local filepath="$(cut -f2 -d' ' <(echo $line))"
    case $operation in
      D)
        rm "$_SANDBOX/$filepath"
        ;;
      A | M | AM)
        ln -sf "$(realpath $filepath)" "$_SANDBOX/$filepath"
        ;;
      **)
        echo "Wuh? $line"
        exit 77
        ;;
    esac
  done

  cd "$_SANDBOX"

  trap teardown EXIT
}

setup
