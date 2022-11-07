echo "${_group}Ensuring files from examples ..."

ensure_file_from_example "$SENTRY_CONFIG_PY"
ensure_file_from_example "$SENTRY_CONFIG_YML"
ensure_file_from_example "$PROJECT_ROOT/symbolicator/config.yml"

echo "${_endgroup}"
