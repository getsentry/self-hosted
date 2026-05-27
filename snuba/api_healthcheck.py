#!/usr/bin/env python3
"""
Healthcheck for the snuba api in self-hosted.

GETs /health on localhost and exits 0 if the response body contains
"ok", else 1. On failure, prints a one-line description to stderr
rather than a full Python traceback, so `docker inspect` output
stays readable.

Mounted into the snuba-api container by docker-compose.yml.
"""

import sys
import urllib.error
import urllib.request

URL = "http://127.0.0.1:1218/health"
TIMEOUT = 2


def main() -> int:
    try:
        body = urllib.request.urlopen(URL, timeout=TIMEOUT).read().decode()
    except urllib.error.HTTPError as exc:
        print(f"snuba /health returned HTTP {exc.code}", file=sys.stderr)
        return 1
    except urllib.error.URLError as exc:
        print(f"snuba /health unreachable: {exc.reason}", file=sys.stderr)
        return 1

    if "ok" not in body:
        print(f"snuba /health body missing 'ok': {body!r}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
