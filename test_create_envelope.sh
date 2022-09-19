#!/usr/bin/env bash
### TODO: DELETE ME!!! THIS SHOULD NOT BE MERGED!
# Experimentation only!
function create_envelope() {
  local cli_output=$1;
  # Get the UUID of event
  local event_fingerprint=${cli_output#Event dispatched: };
  # The event_id is the UUID without dashes
  local event_id=${event_fingerprint//-/};
  local envelope_file="/tmp/sentry-envelope-${event_id}"
  # If the envelope file exists, we've already sent it, so we are done
  if [[ -f envelope_file ]]; then
    return;
  fi
  # If we haven't sent the envelope file, make it and send to Sentry
  # The format is documented at https://develop.sentry.dev/sdk/envelopes/
  # Get length of file, needed for the envelope header
  local file_length=$(wc -c < $log_file);
  echo $(jq -n \
    --arg event_id "$event_id" \
    --arg dsn "$SENTRY_DSN" \
    '{"event_id": $event_id, "dsn": $dsn}' \
  ) > $envelope_file;
  echo $(jq -n \
    --arg length "$file_length" \
    --arg filename "$log_file" \
    '{"type": "attachment", "length": $length, "content_type": "text/plain", "filename": $filename}' \
  ) >> $envelope_file;
  cat $log_file >> $envelope_file;
}
