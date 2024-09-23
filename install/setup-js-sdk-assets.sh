# This will only run if the SETUP_JS_SDK_ASSETS environment variable is set to 1
if [[ "$SETUP_JS_SDK_ASSETS" == "1" ]]; then
  echo "${_group}Setting up JS SDK assets"

  # If the `sentry-nginx-www` volume exists, we need to prune the contents.
  # We don't want to fill the volume with old JS SDK assets.
  # If people want to keep the old assets, they can set the environment variable
  # `SETUP_JS_SDK_KEEP_OLD_ASSETS` to any value.
  if [[ -z "$SETUP_JS_SDK_KEEP_OLD_ASSETS" ]]; then
    echo "Cleaning up old JS SDK assets..."
    docker run --rm -v "sentry-nginx-www:/js-sdk" busybox rm -rf /js-sdk/*
  fi

  $dbuild -t sentry-self-hosted-jq-local --platform="$DOCKER_PLATFORM" jq

  jq="docker run --rm -i sentry-self-hosted-jq-local"

  latest_js_v7=$($dc exec web cat /usr/src/sentry/src/sentry/loader/_registry.json | $jq -r '.versions | reverse | map(select(.|any(.; startswith("7.")))) | .[0]')
  latest_js_v8=$($dc exec web cat /usr/src/sentry/src/sentry/loader/_registry.json | $jq -r '.versions | reverse | map(select(.|any(.; startswith("8.")))) | .[0]')

  # Download those two using wget
  for version in "${latest_js_v7}" "${latest_js_v8}"; do
    for variant in "tracing" "tracing.replay" "replay" "tracing.replay.feedback" "feedback"; do
      docker run --rm -v "sentry-nginx-www:/js-sdk" busybox wget -q -O /js-sdk/${version}/bundle.${variant}.min.js "https://browser.sentry-cdn.com/${version}/bundle.${variant}.min.js"
    done
  done

  echo "${_endgroup}"
fi
