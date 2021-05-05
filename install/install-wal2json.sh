echo "${_group}Downloading and installing wal2json ..."

FILE_TO_USE="../postgres/wal2json/wal2json.so"
ARCH=$(uname -m)
FILE_NAME="wal2json-Linux-$ARCH.so"

DOCKER="docker run --rm"
CURL="curlimages/curl"

if [[ $WAL2JSON_VERSION == "latest" ]]; then
    VERSION=$(
        $DOCKER $CURL https://api.github.com/repos/getsentry/wal2json/releases/latest |
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
    mkdir -p "/tmp/wal2json"
    $DOCKER -v "/tmp/wal2json:/tmp" $CURL \
        "https://github.com/getsentry/wal2json/releases/download/$VERSION/$FILE_NAME" \
        -o /tmp/$FILE_NAME
    mv "/tmp/wal2json/$FILE_NAME" "../postgres/wal2json/$VERSION/$FILE_NAME"
    cp "../postgres/wal2json/$VERSION/$FILE_NAME" "$FILE_TO_USE"
fi  

echo "${_endgroup}"
