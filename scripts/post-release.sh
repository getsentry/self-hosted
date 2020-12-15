#!/bin/bash
set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SCRIPT_DIR/..

# Bring master back to nightlies after merge from release branch

SYMBOLICATOR_VERSION=nightly ./scripts/bump-version.sh '' 'nightly'
git diff --quiet || git commit -anm 'build: Set master version to nightly' && git push
