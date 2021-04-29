echo "${_group}Downloading and installing wal2json ..."

VERSION_FILE="../postgres/wal2json/wal2json.so"
ARCH=$(uname -m)
FILE_NAME="wal2json-Linux-$ARCH.so"

if [[ $WAL2JSON_VERSION == "latest" ]]; then
    VERSION=$(
        wget "https://api.github.com/repos/getsentry/wal2json/releases/latest" -O - |
        grep '"tag_name":' |
        sed -E 's/.*"([^"]+)".*/\1/'
    )

    if [[ ! $VERSION ]]; then
        echo "Cannot find wal2json latest version"
        exit 1
    fi
else
    VERSION=$WAL2JSON_VERSION
fi

mkdir -p ../postgres/wal2json
if [ ! -f "../postgres/wal2json/$VERSION/$FILE_NAME" ]; then
    mkdir -p "../postgres/wal2json/$VERSION"
    wget \
        "https://github.com/getsentry/wal2json/releases/download/$VERSION/$FILE_NAME" \
        -P "../postgres/wal2json/$VERSION/"; then
    ln -s "`pwd`/../postgres/wal2json/$VERSION/$FILE_NAME" "$VERSION_FILE"
fi  

echo "${_endgroup}"
