#!/usr/bin/env bash
set -eEuo pipefail

# Needed variables to source error-handling script
MINIMIZE_DOWNTIME="${MINIMIZE_DOWNTIME:-}"
STOP_TIMEOUT=60

# Save logs in order to send envelope to Sentry
log_file=sentry_"$cmd"_log-$(date +'%Y-%m-%d_%H-%M-%S').txt
exec &> >(tee -a "$log_file")
version=""

while (($#)); do
  case "$1" in
  --report-self-hosted-issues) REPORT_SELF_HOSTED_ISSUES=1 ;;
  --no-report-self-hosted-issues) REPORT_SELF_HOSTED_ISSUES=0 ;;
  *) version=$1 ;;
  esac
  shift
done

# Source files needed to set up error-handling
source install/dc-detect-version.sh
source install/detect-platform.sh
source install/error-handling.sh
trap_with_arg cleanup ERR INT TERM EXIT
