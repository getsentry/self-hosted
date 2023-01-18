set -euo pipefail

source install/_lib.sh

_ORIGIN=$(pwd)

rm -rf /tmp/sentry-self-hosted-test-sandbox.*
_SANDBOX="$(mktemp -d /tmp/sentry-self-hosted-test-sandbox.XXX)"

source install/detect-platform.sh
docker build -t sentry-self-hosted-jq-local --platform="$DOCKER_PLATFORM" jq

report_success() {
  echo "$(basename $0) - Success 👍"
}

teardown() {
  test "${DEBUG:-}" || rm -rf "$_SANDBOX"
  cd "$_ORIGIN"
}

setup() {
  # Clone the local repo into a temp dir. FWIW `git clone --local` breaks for
  # me because it depends on hard-linking, which doesn't work across devices,
  # and I happen to have my workspace and /tmp on separate devices.
  git -c advice.detachedHead=false clone --depth=1 "file://$_ORIGIN" "$_SANDBOX"

  # Now propagate any local changes from the working copy to the sandbox. This
  # provides a pretty nice dev experience: edit the files in the working copy,
  # then run `DEBUG=1 some-test.sh` to leave the sandbox up for interactive
  # dev/debugging.
  git status --porcelain | while read line; do
    # $line here is something like `M some-script.sh`.

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
