echo "${_group}Setting up error handling ..."

export SENTRY_DSN='https://19555c489ded4769978daae92f2346ca@self-hosted.getsentry.net/3'
export SENTRY_ORG=self-hosted
export SENTRY_PROJECT=installer

send_envelope() {
  # Send envelope
  local sentry_cli="docker run --rm -v /tmp:/work -e SENTRY_ORG=$SENTRY_ORG -e SENTRY_PROJECT=$SENTRY_PROJECT -e SENTRY_DSN=$SENTRY_DSN getsentry/sentry-cli"
  $sentry_cli send-envelope $envelope_file
}

send_event() {
  # Use traceback hash as the UUID since it is 32 characters long
  local event_hash=$1
  local traceback=$2
  # escape traceback for quotes so that we are sending valid json
  local traceback_escaped="${traceback//\"/\\\"}"
  local envelope_file="sentry-envelope-${event_hash}"
  local envelope_file_path="/tmp/$envelope_file"
  # If the envelope file exists, we've already sent it
  if [[ -f $envelope_file_path ]]; then
    echo "Looks like you've already sent this error to us, we're on it :)"
    return;
  fi
  # If we haven't sent the envelope file, make it and send to Sentry
  # The format is documented at https://develop.sentry.dev/sdk/envelopes/
  # Grab length of log file, needed for the envelope header to send an attachment
  local file_length=$(wc -c < "$basedir/$log_file" | awk '{print $1}')
  # Add header for initial envelope information
  echo '{"event_id":"'$event_hash'","dsn":"'$SENTRY_DSN'"}' > $envelope_file_path
  # Add header to specify the event type of envelope to be sent
  echo '{"type":"event"}' >> $envelope_file_path
  # Add traceback message to event
  echo '{"message":"'$traceback_escaped'","level":"error"}' >> $envelope_file_path
  # Add attachment to the event
  echo '{"type":"attachment","length":'$file_length',"content_type":"text/plain","filename":"install_log.txt"}' >> $envelope_file_path
  cat "$basedir/$log_file" >> $envelope_file_path
  # Send envelope
  send_envelope $envelope_file
}

if [[ -z "${REPORT_SELF_HOSTED_ISSUES:-}" ]]; then
  if [[ $PROMPTABLE == "0" ]]; then
    echo
    echo "Hey, so ... we would love to automatically find out about issues with your"
    echo "Sentry instance so that we can improve the product. Turns out there is an app"
    echo "for that, called Sentry. Would you be willing to let us automatically send data"
    echo "about your instance upstream to Sentry for development and debugging purposes?"
    echo "If so, rerun with:"
    echo
    echo "  ./install.sh --report-self-hosted-issues"
    echo
    echo "      or"
    echo
    echo "  REPORT_SELF_HOSTED_ISSUES=1 ./install.sh"
    echo
    echo "(Btw, we send this to our own self-hosted Sentry instance, not to Sentry SaaS,"
    echo "so that we can be in this together.)"
    echo
    echo "Here's the info we may collect:"
    echo
    echo "  - OS username"
    echo "  - IP address"
    echo "  - install log"
    echo "  - runtime errors"
    echo "  - performance data"
    echo
    echo "Thirty (30) day retention. No marketing. Privacy policy at sentry.io/privacy."
    echo
    echo "For now we are defaulting to not reporting upstream, but our plan is to"
    echo "hard-require a choice from you starting in version 22.10.0, because let's be"
    echo "honest, none of you will act on this otherwise. To avoid disruption you can use"
    echo "one of these flags:"
    echo
    echo "  --report-self-hosted-issues"
    echo "  --no-report-self-hosted-issues"
    echo
    echo "or set the REPORT_SELF_HOSTED_ISSUES environment variable:"
    echo
    echo "  REPORT_SELF_HOSTED_ISSUES=1 to send data"
    echo "  REPORT_SELF_HOSTED_ISSUES=0 to not send data"
    echo
    echo "Thanks for using Sentry."
    echo
    export REPORT_SELF_HOSTED_ISSUES=0  # opt-in for now
  else
    echo
    echo "Hey, so ... we would love to automatically find out about issues with your"
    echo "Sentry instance so that we can improve the product. Turns out there is an app"
    echo "for that, called Sentry. Would you be willing to let us automatically send data"
    echo "about your instance upstream to Sentry for development and debugging purposes?"
    echo
    echo "  y / yes / 1"
    echo "  n / no / 0"
    echo
    echo "(Btw, we send this to our own self-hosted Sentry instance, not to Sentry SaaS,"
    echo "so that we can be in this together.)"
    echo
    echo "Here's the info we may collect:"
    echo
    echo "  - OS username"
    echo "  - IP address"
    echo "  - install log"
    echo "  - runtime errors"
    echo "  - performance data"
    echo
    echo "Thirty (30) day retention. No marketing. Privacy policy at sentry.io/privacy."
    echo

    yn=""
    until [ ! -z "$yn" ]
    do
      read -p "y or n? " yn
      case $yn in
        y | yes | 1) export REPORT_SELF_HOSTED_ISSUES=1; echo; echo -n "Thank you.";;
        n | no | 0) export REPORT_SELF_HOSTED_ISSUES=0; echo; echo -n "Understood.";;
        *) yn="";;
      esac
    done

    echo " To avoid this prompt in the future, use one of these flags:"
    echo
    echo "  --report-self-hosted-issues"
    echo "  --no-report-self-hosted-issues"
    echo
    echo "or set the REPORT_SELF_HOSTED_ISSUES environment variable:"
    echo
    echo "  REPORT_SELF_HOSTED_ISSUES=1 to send data"
    echo "  REPORT_SELF_HOSTED_ISSUES=0 to not send data"
    echo
    sleep 5
  fi
fi

# Make sure we can use sentry-cli if we need it.
if [ "$REPORT_SELF_HOSTED_ISSUES" == 1 ]; then
  if ! docker pull getsentry/sentry-cli:latest; then
    echo "Failed to pull sentry-cli, won't report to Sentry after all."
    export REPORT_SELF_HOSTED_ISSUES=0
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

    if [ "$REPORT_SELF_HOSTED_ISSUES" == 1 ]; then
      local event_hash=$(echo -n "$cmd_exit $traceback" | docker run -i --rm busybox md5sum | cut -d' ' -f1)
      send_event "$event_hash" "$cmd_exit"
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
