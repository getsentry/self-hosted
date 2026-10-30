"""Apply the optional customizations in this directory to the sentry image.

Run by sentry/Dockerfile at build time.
"""

import os
import pwd
import subprocess
import sys

ENHANCE_IMAGE = "/usr/src/sentry/enhance-image.sh"
REQUIREMENTS = "/usr/src/sentry/requirements.txt"


def is_non_empty_file(path: str) -> bool:
    return os.path.isfile(path) and os.path.getsize(path) > 0


def main() -> int:
    if is_non_empty_file(ENHANCE_IMAGE):
        if not os.path.exists("/bin/sh"):
            print(
                "sentry/enhance-image.sh needs a shell, but this SENTRY_IMAGE has none. "
                "Remove sentry/enhance-image.sh or use an image with a shell.",
                file=sys.stderr,
            )
            return 1
        subprocess.run([ENHANCE_IMAGE], check=True)

    if is_non_empty_file(REQUIREMENTS):
        print(
            "sentry/requirements.txt is deprecated, use sentry/enhance-image.sh - "
            "see https://develop.sentry.dev/self-hosted/#enhance-sentry-image"
        )
        subprocess.run([sys.executable, "-m", "pip", "install", "-r", REQUIREMENTS], check=True)

    # Let the non-root sentry user run update-ca-certificates (sentry/entrypoint.sh)
    # for custom CAs mounted from ./certificates. It only needs to create symlinks
    # and replace the bundle in this directory.
    sentry = pwd.getpwnam("sentry")
    os.chown("/etc/ssl/certs", sentry.pw_uid, sentry.pw_gid)

    return 0


if __name__ == "__main__":
    sys.exit(main())
