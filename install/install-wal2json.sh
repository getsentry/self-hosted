echo "${_group}Downloading and installing wal2json ..."

WAL2JSON_DIR=postgres/wal2json
FILE_TO_USE="$WAL2JSON_DIR/wal2json.so"
ARCH=$(uname -m)
FILE_NAME="wal2json-Linux-$ARCH-glibc.so"

docker_curl() {
  # The environment variables can be specified in lower case or upper case.
  # The lower case version has precedence. http_proxy is an exception as it is only available in lower case.
  docker run --rm -e http_proxy -e https_proxy -e HTTPS_PROXY -e no_proxy -e NO_PROXY curlimages/curl:7.77.0 \
    --connect-timeout 5 \
    --max-time 10 \
    --retry 5 \
    --retry-max-time 60 \
    "$@"
}

if [[ $WAL2JSON_VERSION == "latest" ]]; then
  # Hard-code this. Super-hacky. We were curling the GitHub API here but
  # hitting rate limits in CI. This library hasn't seen a new release for a
  # year and a half at time of writing.
  #
  # If you're reading this do us a favor and go check:
  #
  #   https://github.com/getsentry/wal2json/releases
  #
  # If there's a new release can you update this please? If not maybe subscribe
  # for notifications on the repo with "Watch > Custom > Releases". Together we
  # can make a difference.
  VERSION=0.0.2
else
  VERSION=$WAL2JSON_VERSION
fi

mkdir -p "$WAL2JSON_DIR"
if [ ! -f "$WAL2JSON_DIR/$VERSION/$FILE_NAME" ]; then
  mkdir -p "$WAL2JSON_DIR/$VERSION"
  docker_curl -L \
    "https://github.com/getsentry/wal2json/releases/download/$VERSION/$FILE_NAME" \
    >"$WAL2JSON_DIR/$VERSION/$FILE_NAME"
fi
cp "$WAL2JSON_DIR/$VERSION/$FILE_NAME" "$FILE_TO_USE"

echo "${_endgroup}"
