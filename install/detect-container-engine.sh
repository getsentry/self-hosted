echo "${_group}Detecting container engine ..."

export CONTAINER_ENGINE=""

if command -v podman &> /dev/null; then
    CONTAINER_ENGINE="podman"
elif command -v docker &> /dev/null; then
    CONTAINER_ENGINE="docker"
else
    echo "FAIL: Neither podman nor docker is installed on the system."
    exit 1
fi
echo "Detected container engine: $CONTAINER_ENGINE"
echo "${_endgroup}"