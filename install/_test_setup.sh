set -euo pipefail
test ${DEBUG:-''} && set -x
cd "$(dirname $0)/.."

rm -rf /tmp/sentry-onpremise-test-sandbox.*
_SANDBOX="$(mktemp -d /tmp/sentry-onpremise-test-sandbox.XXX)"

report_success() {
  echo "$(basename $0) - Success 👍"
}

teardown() {
  test ${DEBUG:-''} || rm -rf "$_SANDBOX"
}

setup() {
  # Clone the local repo into a temp dir, and propagate local changes.

  # FWIW `git clone --local` breaks for me because it depends on hard-linking,
  # which doesn't work across devices, and I happen to have my workspace and
  # tmp on separate devices.
  git clone --depth=1 "file://$(pwd)" "$_SANDBOX"

  git status --porcelain | while read line; do

    # $line here is something like `M some-script.sh`. By propagating working
    # copy changes to the sandbox, we can provide a pretty nice dev experience:
    # edit the files in the working copy, then run `DEBUG=1 some-test.sh` to
    # leave the sandbox up for interactive dev/debugging.

    local filepath="$(cut -f2 -d' ' <(echo $line))"
    local filestatus="$(cut -f1 -d' ' <(echo $line))"

    case $filestatus in
      D)
        rm "$_SANDBOX/$filepath"
        ;;
      A | M | AM | ??)
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
