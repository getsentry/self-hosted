#!/usr/bin/env bash

# Needed variable to source install script
MSYSTEM="${MSYSTEM:-}"
log_name=reset

source set-up-error-reporting-for-scripts.sh
source docker_cleanup.sh
source install.sh
