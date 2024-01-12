echo "${_group}Checking for latest commit ... "

# Checks if we are on latest commit from github if it is running from master branch
if [[ -d "../.git" && "${SKIP_COMMIT_CHECK:-0}" != 1 ]]; then
  if [[ $(git branch --show-current) == "master" ]]; then
    if [[ $(git rev-parse HEAD) != $(git ls-remote $(git rev-parse --abbrev-ref @{u} | sed 's/\// /g') | cut -f1) ]]; then
      echo "Seems like you are not using the latest commit from the self-hosted repository. Please pull the latest changes and try again, or suppress this check with --skip-commit-check."
      exit 1
    fi
  fi
else
  echo "skipped"
fi

echo "${_endgroup}"
