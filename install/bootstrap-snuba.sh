echo "${_group}Bootstrapping and migrating Snuba ..."

if [[ -z "${SKIP_SNUBA_MIGRATIONS:-}" ]]; then
  # NOTE(aldy505): Temporarily increase the number of open files to avoid errors
  # Otherwise, we'll get "crun: setrlimit `RLIMIT_NOFILE`: Operation not permitted: OCI permission denied"
  if [[ "$CONTAINER_ENGINE" == "podman" ]]; then
    ulimit -u 100000
  fi
  $dcr snuba-api bootstrap --force
else
  echo "Skipped DB migrations due to SKIP_SNUBA_MIGRATIONS=$SKIP_SNUBA_MIGRATIONS"
fi

echo "${_endgroup}"
