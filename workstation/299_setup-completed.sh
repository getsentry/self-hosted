#!/bin/bash
#

# Add a dot file to the home directory indicating that the setup has been completed successfully.
# The host-side of the connection will look for this file when polling for completion to indicate to
# the user that the workstation is ready for use.
#
# Works under the assumption that this is the last setup script to run!
echo "ready_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >/home/user/.sentry.workstation.remote
