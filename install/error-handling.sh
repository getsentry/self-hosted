echo "${_group}Setting up error handling ..."

export SENTRY_DSN='https://afa81b4b7c634e318b0ec138abb2645f@self-hosted.getsentry.net/2'
export SENTRY_ORG=sentry
export SENTRY_PROJECT=dogfooding

function err_info {
  local retcode=$?
  local cmd="${BASH_COMMAND}"
  if [[ $retcode -ne 0 ]]; then
    set +o xtrace
    echo "Error in ${BASH_SOURCE[0]}:${BASH_LINENO[0]}." >&2
    echo "'$cmd' exited with status $retcode" >&2
    local stack_depth=${#FUNCNAME[@]}
    if [ $stack_depth -gt 2 ]; then
      for ((i=$(($stack_depth - 1)),j=1;i>0;i--,j++)); do
          local indent="$(yes a | head -$j | tr -d '\n')"
          local src=${BASH_SOURCE[$i]}
          local lineno=${BASH_LINENO[$i-1]}
          local funcname=${FUNCNAME[$i]}
          echo "${indent//a/-}>$src:$funcname:$lineno" >&2
      done
    fi
  fi
  echo "Exiting with code $retcode" >&2
  exit $retcode
}

# Courtesy of https://stackoverflow.com/a/2183063/90297
trap_with_arg() {
  func="$1" ; shift
  for sig ; do
    trap "$func $sig "'$LINENO' "$sig"
  done
}

DID_CLEAN_UP=0
# the cleanup function will be the exit point
cleanup () {
  if [[ "$DID_CLEAN_UP" -eq 1 ]]; then
    return 0;
  fi
  DID_CLEAN_UP=1

  if [[ "$1" != "EXIT" ]]; then
    echo "An error occurred, caught SIG$1 on line $2";

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
trap_with_arg cleanup ERR INT TERM EXIT

echo "${_endgroup}"
