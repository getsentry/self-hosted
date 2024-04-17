#!/bin/bash
#

# Install self-hosted. Assumed `200_download-self-hosted.sh` has already run.
./install.sh --skip-commit-check --skip-user-creation --skip-sse42-requirements --no-report-self-hosted-issues

# Apply CSRF override to the newly installed sentry settings.
echo "CSRF_TRUSTED_ORIGINS = [\"https://9000-$WEB_HOST\"]" >>/home/user/getsentry/self-hosted/sentry/sentry.conf.py
