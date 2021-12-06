#!/bin/bash

# Checks if we are on latest commit from github if it is running from master branch
if [[ -d ".git" && "${NOT_LATEST_COMMIT:-0}" != 1 ]]; then
  if [[ $(git branch | sed -n '/\* /s///p') == "master" ]]; then
    if [[ $(git rev-parse HEAD) != $(git ls-remote $(git rev-parse --abbrev-ref @{u} | sed 's/\// /g') | cut -f1) ]]; then
      echo "Seems like you are not using the latest commit from self-hosted repository. Please pull the latest changes and try again.";
      exit 1
    fi
  fi
fi
