echo "${_group}Updating feature flags..."
# This script updates the SENTRY_FEATURES block in sentry/sentry.conf.py
# (or $SENTRY_CONFIG_PY) to match sentry/sentry.conf.example.py.
# It only runs when APPLY_AUTOMATIC_CONFIG_UPDATES=1.

if [[ "${APPLY_AUTOMATIC_CONFIG_UPDATES:-0}" == 1 ]]; then
  echo "Applying automatic config updates..."

  _example_config="sentry/sentry.conf.example.py"

  # Extract the canonical SENTRY_FEATURES block from the example config.
  # The block starts at the first line matching the sample-events key
  # and ends at the first lone `)` closing SENTRY_FEATURES.update(...).
  _example_block=$(sed -n '/^SENTRY_FEATURES\["projects:sample-events"\]/,/^)$/p' "$_example_config")

  if [[ -z "$_example_block" ]]; then
    echo "ERROR: Could not extract SENTRY_FEATURES block from $_example_config."
    echo "The expected start marker (SENTRY_FEATURES[\"projects:sample-events\"]) was not found."
    echo "Skipping feature flag update to avoid corrupting your config."
  else
    # Check if the user's config already has a SENTRY_FEATURES block.
    if ! grep -q '^SENTRY_FEATURES' "$SENTRY_CONFIG_PY"; then
      # No existing block, append the canonical block.
      printf '\n%s\n' "$_example_block" >>"$SENTRY_CONFIG_PY"
      echo "Added SENTRY_FEATURES block to $SENTRY_CONFIG_PY."
    else
      # Replace the existing SENTRY_FEATURES block with the canonical one.
      # Find the start and end lines of the existing block.
      _start_line=$(grep -n '^SENTRY_FEATURES' "$SENTRY_CONFIG_PY" | head -1 | cut -d: -f1)

      # Find the closing `)`, the first line after _start_line that is exactly `)`.
      _end_line=$(awk -v start="$_start_line" 'NR > start && /^\)$/ { print NR; exit }' "$SENTRY_CONFIG_PY")

      if [[ -z "$_end_line" ]]; then
        # No closing `)` found before EOF,  replace from start to EOF.
        _end_line=$(wc -l <"$SENTRY_CONFIG_PY")
      fi

      # Build the new config: lines before the block, the canonical block, lines after.
      {
        # Lines before the SENTRY_FEATURES block.
        head -n "$((_start_line - 1))" "$SENTRY_CONFIG_PY"
        # The canonical block.
        echo "$_example_block"
        # Lines after the SENTRY_FEATURES block (if any).
        tail -n +"$((_end_line + 1))" "$SENTRY_CONFIG_PY"
      } >"$SENTRY_CONFIG_PY.tmp" && mv "$SENTRY_CONFIG_PY.tmp" "$SENTRY_CONFIG_PY"

      echo "Updated SENTRY_FEATURES block in $SENTRY_CONFIG_PY."
    fi
  fi
else
  echo "Skipping feature flag updates (set APPLY_AUTOMATIC_CONFIG_UPDATES=1 to apply)."
fi
echo "${_endgroup}"
