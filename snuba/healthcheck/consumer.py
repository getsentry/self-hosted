#!/usr/bin/env python3
"""
Healthcheck for snuba consumer-like services in self-hosted.

Deletes the consumer heartbeat file (/tmp/health.txt) that the
consumer re-creates on every healthy iteration when started with
`--health-check-file /tmp/health.txt`. If the file is missing,
the consumer has not written it since the last check, so the
consumer is considered unhealthy.

Exits 0 if the file existed and was removed, 1 otherwise. On
failure, prints a one-line description to stderr rather than a
full Python traceback so `docker inspect` output stays readable.

Mounted into snuba consumer containers by docker-compose.yml.
"""

import os
import sys

PATH = "/tmp/health.txt"


def main() -> int:
    try:
        os.remove(PATH)
    except FileNotFoundError:
        print(f"consumer heartbeat file missing: {PATH}", file=sys.stderr)
        return 1
    except OSError as exc:
        print(f"could not remove heartbeat file {PATH}: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
