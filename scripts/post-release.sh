#!/bin/bash
set -eu

# Bring master back to nightlies after merge from release branch
git checkout master && git pull --rebase
./scripts/bump-version.sh '' 'nightly'
git diff --quiet || git commit -anm $'build: Set master version to nightly\n\n#skip-changelog' && git pull --rebase && git push
