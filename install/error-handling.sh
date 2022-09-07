echo "${_group}Setting up error handling ..."

export SENTRY_DSN='https://19555c489ded4769978daae92f2346ca@self-hosted.getsentry.net/3'
export SENTRY_ORG=sentry
export SENTRY_PROJECT=installer

if [[ -f .reporterrors ]]; then
  if [[ "$(cat .reporterrors)" == "yes" ]]; then
    export REPORT_ERRORS=1
  else
    export REPORT_ERRORS=0
  fi
else
  echo "Would you like to opt-in to error monitoring for the Sentry installer?"
  echo "This helps us catch and fix errors when installing Sentry."
  echo "We may collect and retain your OS username, IP address, and installer log, for 30 days."
  echo "Your information is solely used to improve the installer and is subject to our privacy policy[1]."
  echo "You may change your preference at any time by deleting the '.reporterrors' file."
  echo
  echo "[1] https://sentry.io/privacy/"
  select yn in "Yes" "No"; do
      case $yn in
          Yes ) export REPORT_ERRORS=1; echo "yes" > .reporterrors; break;;
          No ) export REPORT_ERRORS=0; echo "no" > .reporterrors; break;;
      esac
  done
fi

# Courtesy of https://stackoverflow.com/a/2183063/90297
trap_with_arg() {
  func="$1" ; shift
  for sig ; do
    trap "$func $sig" "$sig"
  done
}

DID_CLEAN_UP=0
# the cleanup function will be the exit point
cleanup () {
  if [[ "$DID_CLEAN_UP" -eq 1 ]]; then
    return 0;
  fi
  DID_CLEAN_UP=1
  local retcode=$?
  local cmd="${BASH_COMMAND}"
  if [[ "$1" != "EXIT" ]]; then
    set +o xtrace
    printf -v err '%s' "Error in ${BASH_SOURCE[1]}:${BASH_LINENO[1]}."
    printf -v cmd_exit '%s' "'$cmd' exited with status $retcode"
    printf '%s\n%s\n' "$err" "$cmd_exit"
    local stack_depth=${#FUNCNAME[@]}
    local traceback=""
    if [ $stack_depth -gt 2 ]; then
      for ((i=$(($stack_depth - 1)),j=1;i>0;i--,j++)); do
          local indent="$(yes a | head -$j | tr -d '\n')"
          local src=${BASH_SOURCE[$i]}
          local lineno=${BASH_LINENO[$i-1]}
          local funcname=${FUNCNAME[$i]}
          printf -v traceback '%s\n' "$traceback${indent//a/-}>$src:$funcname:$lineno"
      done
    fi
    echo "$traceback"

    if [ "$REPORT_ERRORS" == 1 ]; then
      local traceback_hash=$(echo -n $traceback | docker run --rm busybox md5sum | cut -d' ' -f1)
      send_event "$traceback_hash" "$cmd_exit"
    fi

    if [[ -n "$MINIMIZE_DOWNTIME" ]]; then
      echo "*NOT* cleaning up, to clean your environment run \"docker compose stop\"."
    else
      echo "Cleaning up..."
    fi
  fi

  if [[ -z "$MINIMIZE_DOWNTIME" ]]; then
    $dc stop -t $STOP_TIMEOUT &> /dev/null
  fi
}

echo "${_endgroup}"
