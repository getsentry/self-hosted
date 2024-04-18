#!/bin/bash
#

# Create getsentry folder and enter.
mkdir /home/user/getsentry
cd /home/user/getsentry

# Pull down sentry and self-hosted.
git clone https://github.com/getsentry/sentry.git
git clone https://github.com/getsentry/self-hosted.git
cd self-hosted
