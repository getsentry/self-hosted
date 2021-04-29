echo "${_group}Downloading and installing wal2json ..."

LATEST_VERSION_FILE="../postgres/wal2json/wal2json.so"
ARCH=$(uname -m)
FILE_NAME="wal2json-Linux-$ARCH.so"
LATEST_VERSION=$(
    wget "https://api.github.com/repos/getsentry/wal2json/releases/latest" -O - |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
)

mkdir -p ../postgres/wal2json
if [[ $LATEST_VERSION ]]; then
    if [ ! -f "../postgres/wal2json/$LATEST_VERSION/$FILE_NAME" ]; then
        mkdir -p "../postgres/wal2json/$LATEST_VERSION"
        if wget \
            "https://github.com/getsentry/wal2json/releases/download/$LATEST_VERSION/$FILE_NAME" \
            -P "../postgres/wal2json/$LATEST_VERSION/"; then
            ln -s "`pwd`/../postgres/wal2json/$LATEST_VERSION/$FILE_NAME" "$LATEST_VERSION_FILE"
        fi
    fi
else
    echo "wal2json is not installed and cannot download latest version"
    exit 1
fi

set -e

echo "${_endgroup}"
