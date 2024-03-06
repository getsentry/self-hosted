echo "${_group}Setting up error handling ..."

if [ -z "${SENTRY_DSN:-}" ]; then
  export SENTRY_DSN='https://19555c489ded4769978daae92f2346ca@self-hosted.getsentry.net/3'
fi

$dbuild -t sentry-self-hosted-jq-local --platform="$DOCKER_PLATFORM" jq

jq="docker run --rm -i sentry-self-hosted-jq-local"
sentry_cli="docker run --rm -v /tmp:/work -e SENTRY_DSN=$SENTRY_DSN getsentry/sentry-cli"

send_envelope() {
  # Send envelope
  $sentry_cli send-envelope "$envelope_file"
}

generate_breadcrumb_json() {
  cat $log_file | $jq -R -c 'split("\n") | {"message": (.[0]//""), "category": "log", "level": "info"}'
}

send_event() {
  # Use traceback hash as the UUID since it is 32 characters long
  local cmd_exit=$1
  local error_msg=$2
  local traceback=$3
  local traceback_json=$4
  local breadcrumbs=$5
  local fingerprint_value=$(
    echo -n "$cmd_exit $error_msg $traceback" |
      docker run -i --rm busybox md5sum |
      cut -d' ' -f1
  )
  local envelope_file="sentry-envelope-${fingerprint_value}"
  local envelope_file_path="/tmp/$envelope_file"
  # If the envelope file exists, we've already sent it
  if [[ -f $envelope_file_path ]]; then
    echo "Looks like you've already sent this error to us, we're on it :)"
    return
  fi
  # If we haven't sent the envelope file, make it and send to Sentry
  # The format is documented at https://develop.sentry.dev/sdk/envelopes/
  # Grab length of log file, needed for the envelope header to send an attachment
  local file_length=$(wc -c <$log_file | awk '{print $1}')

  # Add header for initial envelope information
  $jq -n -c --arg event_id "$fingerprint_value" \
    --arg dsn "$SENTRY_DSN" \
    '$ARGS.named' >"$envelope_file_path"
  # Add header to specify the event type of envelope to be sent
  echo '{"type":"event"}' >>"$envelope_file_path"

  # Next we construct the meat of the event payload, which we build up
  # inside out using jq
  # See https://develop.sentry.dev/sdk/event-payloads/
  # for details about the event payload

  # Then we need the exception payload
  # https://develop.sentry.dev/sdk/event-payloads/exception/
  # but first we need to make the stacktrace which goes in the exception payload
  frames=$(echo "$traceback_json" | $jq -s -c)
  stacktrace=$($jq -n -c --argjson frames "$frames" '$ARGS.named')
  exception=$(
    $jq -n -c --arg "type" Error \
      --arg value "$error_msg" \
      --argjson stacktrace "$stacktrace" \
      '$ARGS.named'
  )

  # It'd be a bit cleaner in the Sentry UI if we passed the inputs to
  # fingerprint_value hash rather than the hash itself (I believe the ultimate
  # hash ends up simply being a hash of our hash), but we want the hash locally
  # so that we can avoid resending the same event (design decision to avoid
  # spam in the system). It was also futzy to figure out how to get the
  # traceback in there properly. Meh.
  event_body=$(
    $jq -n -c --arg level error \
      --argjson exception "{\"values\":[$exception]}" \
      --argjson breadcrumbs "{\"values\": $breadcrumbs}" \
      --argjson fingerprint "[\"$fingerprint_value\"]" \
      '$ARGS.named'
  )
  echo "$event_body" >>$envelope_file_path
  # Add attachment to the event
  attachment=$(
    $jq -n -c --arg "type" attachment \
      --arg length "$file_length" \
      --arg content_type "text/plain" \
      --arg filename install_log.txt \
      '{"type": $type,"length": $length|tonumber,"content_type": $content_type,"filename": $filename}'
  )
  echo "$attachment" >>$envelope_file_path
  cat $log_file >>$envelope_file_path
  # Send envelope
  send_envelope $envelope_file
}

if [[ -z "${REPORT_SELF_HOSTED_ISSUES:-}" ]]; then
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
  until [ ! -z "$yn" ]; do
    read -p "y or n? " yn
    case $yn in
    y | yes | 1)
      export REPORT_SELF_HOSTED_ISSUES=1
      echo
      echo -n "Thank you."
      ;;
    n | no | 0)
      export REPORT_SELF_HOSTED_ISSUES=0
      echo
      echo -n "Understood."
      ;;
    *) yn="" ;;
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

# Make sure we can use sentry-cli if we need it.
if [ "$REPORT_SELF_HOSTED_ISSUES" == 1 ]; then
  if ! docker pull getsentry/sentry-cli:latest; then
    echo "Failed to pull sentry-cli, won't report to Sentry after all."
    export REPORT_SELF_HOSTED_ISSUES=0
  fi
fi

# Courtesy of https://stackoverflow.com/a/2183063/90297
trap_with_arg() {
  func="$1"
  shift
  for sig; do
    trap "$func $sig" "$sig"
  done
}

DID_CLEAN_UP=0
# the cleanup function will be the exit point
cleanup() {
  local retcode=$?
  local cmd="${BASH_COMMAND}"
  if [[ "$DID_CLEAN_UP" -eq 1 ]]; then
    return 0
  fi
  DID_CLEAN_UP=1
  if [[ "$1" != "EXIT" ]]; then
    set +o xtrace
    # Save the error message that comes from the last line of the log file
    error_msg=$(tail -n 1 "$log_file")
    # Create the breadcrumb payload now before stacktrace is printed
    # https://develop.sentry.dev/sdk/event-payloads/breadcrumbs/
    # Use sed to remove the last line, that is reported through the error message
    breadcrumbs=$(generate_breadcrumb_json | sed '$d' | $jq -s -c)
    printf -v err '%s' "Error in ${BASH_SOURCE[1]}:${BASH_LINENO[0]}."
    printf -v cmd_exit '%s' "'$cmd' exited with status $retcode"
    printf '%s\n%s\n' "$err" "$cmd_exit"
    local stack_depth=${#FUNCNAME[@]}
    local traceback=""
    local traceback_json=""
    if [ $stack_depth -gt 2 ]; then
      for ((i = $(($stack_depth - 1)), j = 1; i > 0; i--, j++)); do
        local indent="$(yes a | head -$j | tr -d '\n')"
        local src=${BASH_SOURCE[$i]}
        local lineno=${BASH_LINENO[$i - 1]}
        local funcname=${FUNCNAME[$i]}
        JSON=$(
          $jq -n -c --arg filename "$src" \
            --arg "function" "$funcname" \
            --arg lineno "$lineno" \
            '{"filename": $filename, "function": $function, "lineno": $lineno|tonumber}'
        )
        # If we're in the stacktrace of the file we failed on, we can add a context line with the command run that failed
        if [[ $i -eq 1 ]]; then
          JSON=$(
            $jq -n -c --arg cmd "$cmd" \
              --argjson json "$JSON" \
              '$json + {"context_line": $cmd}'
          )
        fi
        printf -v traceback_json '%s\n' "$traceback_json$JSON"
        printf -v traceback '%s\n' "$traceback${indent//a/-}> $src:$funcname:$lineno"
      done
    fi
    echo "$traceback"

    # Only send event when report issues flag is set and if trap signal is not INT (ctrl+c)
    if [[ "$REPORT_SELF_HOSTED_ISSUES" == 1 && "$1" != "INT" ]]; then
      send_event "$cmd_exit" "$error_msg" "$traceback" "$traceback_json" "$breadcrumbs"
    fi

    if [[ -n "$MINIMIZE_DOWNTIME" ]]; then
      echo "*NOT* cleaning up, to clean your environment run \"docker compose stop\"."
    else
      echo "Cleaning up..."
    fi
  fi

  if [[ -z "$MINIMIZE_DOWNTIME" ]]; then
    $dc stop -t $STOP_TIMEOUT &>/dev/null
  fi
}

echo "${_endgroup}"
