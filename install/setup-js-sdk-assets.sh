# This will only run if the SETUP_JS_SDK_ASSETS environment variable is set to 1.
# Think of this as some kind of a feature flag.
if [[ "${SETUP_JS_SDK_ASSETS:-}" == "1" ]]; then
  echo "${_group}Setting up JS SDK assets"

  # If the `sentry-nginx-www` volume exists, we need to prune the contents.
  # We don't want to fill the volume with old JS SDK assets.
  # If people want to keep the old assets, they can set the environment variable
  # `SETUP_JS_SDK_KEEP_OLD_ASSETS` to any value.
  if [[ -z "${SETUP_JS_SDK_KEEP_OLD_ASSETS:-}" ]]; then
    echo "Cleaning up old JS SDK assets..."
    $dcr --no-deps --rm -v "sentry-nginx-www:/var/www" nginx rm -rf /var/www/js-sdk/*
  fi

  $dbuild -t sentry-self-hosted-jq-local --platform="$DOCKER_PLATFORM" jq

  jq="docker run --rm -i sentry-self-hosted-jq-local"

  loader_registry=$($dcr --no-deps --rm -T web cat /usr/src/sentry/src/sentry/loader/_registry.json)
  # The `loader_registry` should start with "Updating certificates...", we want to delete that and the subsequent ca-certificates related lines.
  # We want to remove everything before the first '{'.
  loader_registry=$(echo "$loader_registry" | sed '0,/{/s/[^{]*//')

  latest_js_v7=$(echo "$loader_registry" | $jq -r '.versions | reverse | map(select(.|any(.; startswith("7.")))) | .[0]')
  latest_js_v8=$(echo "$loader_registry" | $jq -r '.versions | reverse | map(select(.|any(.; startswith("8.")))) | .[0]')

  echo "Found JS SDKs v${latest_js_v7} and v${latest_js_v8}, downloading from upstream.."

  # Download those two using wget
  for version in "${latest_js_v7}" "${latest_js_v8}"; do
    $dcr --no-deps --rm -v "sentry-nginx-www:/var/www" nginx mkdir -p /var/www/js-sdk/${version}
    for variant in "tracing" "tracing.replay" "replay" "tracing.replay.feedback" "feedback"; do
      $dcr --no-deps --rm -v "sentry-nginx-www:/var/www" nginx wget -q -O /var/www/js-sdk/${version}/bundle.${variant}.min.js "https://browser.sentry-cdn.com/${version}/bundle.${variant}.min.js"
    done
  done

  echo "${_endgroup}"
fi
