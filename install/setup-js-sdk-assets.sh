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

  #  Sentry backend provides SDK versions from v4.x up to v8.x.
  latest_js_v4=$(echo "$loader_registry" | $jq -r '.versions | reverse | map(select(.|any(.; startswith("4.")))) | .[0]')
  latest_js_v5=$(echo "$loader_registry" | $jq -r '.versions | reverse | map(select(.|any(.; startswith("5.")))) | .[0]')
  latest_js_v6=$(echo "$loader_registry" | $jq -r '.versions | reverse | map(select(.|any(.; startswith("6.")))) | .[0]')
  latest_js_v7=$(echo "$loader_registry" | $jq -r '.versions | reverse | map(select(.|any(.; startswith("7.")))) | .[0]')
  latest_js_v8=$(echo "$loader_registry" | $jq -r '.versions | reverse | map(select(.|any(.; startswith("8.")))) | .[0]')

  echo "Found JS SDKs: v${latest_js_v4}, v${latest_js_v5}, v${latest_js_v6}, v${latest_js_v7}, v${latest_js_v8}"

  versions=( "$latest_js_v4" "$latest_js_v5" "$latest_js_v6" "$latest_js_v7" "$latest_js_v8" )
  variants=( "bundle" "bundle.tracing" "bundle.tracing.replay" "bundle.replay" "bundle.tracing.replay.feedback" "bundle.feedback" )

  # Download those versions & variants using curl
  for version in "${versions[@]}"; do
    $dcr --no-deps --rm -v "sentry-nginx-www:/var/www" nginx mkdir -p /var/www/js-sdk/${version}
    for variant in "${variants[@]}"; do
      # We want to have a HEAD lookup. If the response status code is not 200, we will skip the variant.
      # Taken from https://superuser.com/questions/272265/getting-curl-to-output-http-status-code#comment1025992_272273
      status_code=$($dcr --no-deps --rm nginx curl --retry 5 -sLI "https://browser.sentry-cdn.com/${version}/${variant}.min.js" 2>/dev/null | head -n 1 | cut -d$' ' -f2)
      if [[ "$status_code" != "200" ]]; then
        echo "Skipping download of JS SDK v${version} for ${variant}.min.js, because the status code was ${status_code} (non 200)"
        continue
      fi

      echo "Downloading JS SDK v${version} for ${variant}.min.js..."
      $dcr --no-deps --rm -v "sentry-nginx-www:/var/www" nginx curl --retry 10 -sLo /var/www/js-sdk/${version}/${variant}.min.js "https://browser.sentry-cdn.com/${version}/${variant}.min.js"
    done
  done

  echo "${_endgroup}"
fi
