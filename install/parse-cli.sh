echo "${_group}Parsing command line ..."

show_help() {
  cat <<EOF
Usage: $0 [options]

Install Sentry with \`docker|podman compose\`.

Options:
 -h, --help             Show this message and exit.
 --minimize-downtime    EXPERIMENTAL: try to keep accepting events for as long
                          as possible while upgrading. This will disable cleanup
                          on error, and might leave your installation in a
                          partially upgraded state. This option might not reload
                          all configuration, and is only meant for in-place
                          upgrades.
 --skip-commit-check    Skip the check for the latest commit when on the master
                          branch of a \`self-hosted\` Git working copy.
 --skip-user-creation   Skip the initial user creation prompt (ideal for non-
                          	interactive installs).
 --skip-sse42-requirements
			Skip checking that your environment meets the
			  requirements to run Sentry. Only do this if you know
			  what you are doing.
 --report-self-hosted-issues
                        Report error and performance data about your self-hosted
                          instance upstream to Sentry. See sentry.io/privacy for
                          our privacy policy.
 --no-report-self-hosted-issues
                        Do not report error and performance data about your
                          self-hosted instance upstream to Sentry.
 --container-engine-podman
                        Use podman as the container engine.
 --apply-automatic-config-updates
                        Apply automatic config file updates.
 --no-apply-automatic-config-updates
                        Do not apply automatic config file updates.
EOF
}

depwarn() {
  echo "WARNING The $1 is deprecated. Please use $2 instead."
}

if [ ! -z "${SKIP_USER_PROMPT:-}" ]; then
  depwarn "SKIP_USER_PROMPT variable" "SKIP_USER_CREATION"
  SKIP_USER_CREATION="${SKIP_USER_PROMPT}"
  APPLY_AUTOMATIC_CONFIG_UPDATES="${SKIP_USER_PROMPT}"
fi

SKIP_USER_CREATION="${SKIP_USER_CREATION:-}"
MINIMIZE_DOWNTIME="${MINIMIZE_DOWNTIME:-}"
SKIP_COMMIT_CHECK="${SKIP_COMMIT_CHECK:-}"
REPORT_SELF_HOSTED_ISSUES="${REPORT_SELF_HOSTED_ISSUES:-}"
SKIP_SSE42_REQUIREMENTS="${SKIP_SSE42_REQUIREMENTS:-}"
CONTAINER_ENGINE_PODMAN="${CONTAINER_ENGINE_PODMAN:-}"
APPLY_AUTOMATIC_CONFIG_UPDATES="${APPLY_AUTOMATIC_CONFIG_UPDATES:-}"

while (($#)); do
  case "$1" in
  -h | --help)
    show_help
    exit
    ;;
  --no-user-prompt)
    SKIP_USER_CREATION=1
    depwarn "--no-user-prompt flag" "--skip-user-creation"
    ;;
  --skip-user-prompt)
    SKIP_USER_CREATION=1
    depwarn "--skip-user-prompt flag" "--skip-user-creation"
    ;;
  --skip-user-creation) SKIP_USER_CREATION=1 ;;
  --minimize-downtime) MINIMIZE_DOWNTIME=1 ;;
  --skip-commit-check) SKIP_COMMIT_CHECK=1 ;;
  --report-self-hosted-issues) REPORT_SELF_HOSTED_ISSUES=1 ;;
  --no-report-self-hosted-issues) REPORT_SELF_HOSTED_ISSUES=0 ;;
  --skip-sse42-requirements) SKIP_SSE42_REQUIREMENTS=1 ;;
  --container-engine-podman) CONTAINER_ENGINE_PODMAN=1 ;;
  --apply-automatic-config-updates) APPLY_AUTOMATIC_CONFIG_UPDATES=1 ;;
  --no-apply-automatic-config-updates) APPLY_AUTOMATIC_CONFIG_UPDATES=0 ;;
  --) ;;
  *)
    echo "Unexpected argument: $1. Use --help for usage information."
    exit 1
    ;;
  esac
  shift
done

echo "${_endgroup}"
