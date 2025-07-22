echo "${_group}Detecting container engine ..."

if [[ "${CONTAINER_ENGINE_PODMAN:-0}" -eq 1 ]] && command -v podman &>/dev/null; then
  export CONTAINER_ENGINE="podman"
elif command -v docker &>/dev/null; then
  export CONTAINER_ENGINE="docker"
else
  echo "FAIL: Neither podman nor docker is installed on the system."
  exit 1
fi
echo "Detected container engine: $CONTAINER_ENGINE"
echo "${_endgroup}"
