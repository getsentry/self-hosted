echo "${_group}Setting up error handling ..."

export SENTRY_DSN='https://19555c489ded4769978daae92f2346ca@self-hosted.getsentry.net/3'
export SENTRY_ORG=self-hosted
export SENTRY_PROJECT=installer
export REPORT_ERRORS=0

function send_event {
  local sentry_cli="docker run --rm -v $basedir:/work -e SENTRY_ORG=$SENTRY_ORG -e SENTRY_PROJECT=$SENTRY_PROJECT -e SENTRY_DSN=$SENTRY_DSN getsentry/sentry-cli"
  command pushd .. > /dev/null
  $sentry_cli send-event --no-environ -f "$1" -m "$2" --logfile $log_file
  command popd > /dev/null
}

reporterrors="$basedir/.reporterrors"
if [[ -f $reporterrors ]]; then
  echo -n "Found a .reporterrors file. What does it say? "
  cat $reporterrors
  if [[ "$(cat $reporterrors)" == "yes" ]]; then
    export REPORT_ERRORS=1
  else
    export REPORT_ERRORS=0
  fi
else
  echo
  echo "Hey, so ... we would love to find out when you hit an issue with this here"
  echo "installer you are running. Turns out there is an app for that, called Sentry."
  echo "Are you okay with us sending info to Sentry when you run this installer?"
  echo
  echo "  y / yes / 1"
  echo "  n / no / 0"
  echo
  echo "(Btw, we send this to our own self-hosted Sentry instance, not to Sentry SaaS,"
  echo "so that we can be in this together.)"
  echo
  echo "Here's the info we may collect in order to help us improve the installer:"
  echo
  echo "  - OS username"
  echo "  - IP address"
  echo "  - install log"
  echo "  - performance data"
  echo
  echo "Thirty (30) day retention. No marketing. Privacy policy at sentry.io/privacy."
  echo

  yn=""
  until [ ! -z "$yn" ]
  do
    read -p "y or n? " yn
    case $yn in
      y | yes | 1) export REPORT_ERRORS=1; echo "yes" > $reporterrors; echo; echo -n "Thank you.";;
      n | no | 0) export REPORT_ERRORS=0; echo "no" > $reporterrors; echo; echo -n "Understood.";;
      *) yn="";;
    esac
  done

  echo " Your answer is cached in '.reporterrors', remove it to see this"
  echo "prompt again."
  echo
  sleep 5
fi

# Make sure we can use sentry-cli if we need it.
if [ "$REPORT_ERRORS" == 1 ]; then
  if ! docker pull getsentry/sentry-cli:latest; then
    echo "Failed to pull sentry-cli, won't report errors after all."
    export REPORT_ERRORS=0
  fi;
fi;

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
  local retcode=$?
  local cmd="${BASH_COMMAND}"
  if [[ "$DID_CLEAN_UP" -eq 1 ]]; then
    return 0;
  fi
  DID_CLEAN_UP=1
  if [[ "$1" != "EXIT" ]]; then
    set +o xtrace
    printf -v err '%s' "Error in ${BASH_SOURCE[1]}:${BASH_LINENO[0]}."
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
          printf -v traceback '%s\n' "$traceback${indent//a/-}> $src:$funcname:$lineno"
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
