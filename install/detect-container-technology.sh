echo "${_group}Detecting container technology ..."

export CONTAINER_TECHNOLOGY=""

if command -v podman &> /dev/null; then
    CONTAINER_TECHNOLOGY="podman"
elif command -v docker &> /dev/null; then
    CONTAINER_TECHNOLOGY="docker"
else
    echo "FAIL: Neither podman nor docker is installed on the system."
    exit 1
fi
echo "Detected container technology: $CONTAINER_TECHNOLOGY"
echo "${_endgroup}"