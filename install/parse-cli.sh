echo "${_group}Parsing command line ..."

show_help() {
  cat <<EOF
Usage: $0 [options]

Install Sentry with docker-compose.

Options:
 -h, --help             Show this message and exit.
 --no-user-prompt       Skips the initial user creation prompt (ideal for non-interactive installs).
 --minimize-downtime    EXPERIMENTAL: try to keep accepting events for as long as possible while upgrading.
                        This will disable cleanup on error, and might leave your installation in partially upgraded state.
                        This option might not reload all configuration, and is only meant for in-place upgrades.
EOF
}

SKIP_USER_PROMPT="${SKIP_USER_PROMPT:-}"
MINIMIZE_DOWNTIME="${MINIMIZE_DOWNTIME:-}"

while (( $# )); do
  case "$1" in
    -h | --help) show_help; exit;;
    --no-user-prompt) SKIP_USER_PROMPT=1;;
    --minimize-downtime) MINIMIZE_DOWNTIME=1;;
    --) ;;
    *) echo "Unexpected argument: $1. Use --help for usage information."; exit 1;;
  esac
  shift
done

echo "${_endgroup}"
