#!/usr/bin/env bash
MINIMIZE_DOWNTIME="${MINIMIZE_DOWNTIME:-}"
REPORT_SELF_HOSTED_ISSUES="${REPORT_SELF_HOSTED_ISSUES:-}"

while (($#)); do
  case "$1" in
  --report-self-hosted-issues) REPORT_SELF_HOSTED_ISSUES=1 ;;
  --no-report-self-hosted-issues) REPORT_SELF_HOSTED_ISSUES=0 ;;
  --minimize-downtime) MINIMIZE_DOWNTIME=1 ;;
  *) version=$1 ;;
  esac
  shift
done

cmd="backup $1"
source scripts/_lib.sh
$cmd
