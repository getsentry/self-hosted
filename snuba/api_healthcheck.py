#!/usr/bin/env python3
"""
Healthcheck for the snuba api in self-hosted.

GETs the snuba health endpoint and exits 0 if the response body
contains "ok", else 1. On failure, prints a one-line description to
stderr rather than a full Python traceback, so `docker inspect`
output stays readable.

Mounted into the snuba-api container by docker-compose.yml.

Optional overrides — set in the snuba-api container's environment
(e.g. via your own docker-compose.override.yml) if the defaults
don't fit:

    SNUBA_API_HEALTHCHECK_URL      default http://127.0.0.1:1218/health
    SNUBA_API_HEALTHCHECK_TIMEOUT  default 2 (seconds)
"""

import os
import sys
import urllib.error
import urllib.request

URL = os.environ.get("SNUBA_API_HEALTHCHECK_URL") or "http://127.0.0.1:1218/health"
TIMEOUT = float(os.environ.get("SNUBA_API_HEALTHCHECK_TIMEOUT") or 2)


def main() -> int:
    try:
        body = urllib.request.urlopen(URL, timeout=TIMEOUT).read().decode()
    except urllib.error.HTTPError as exc:
        print(f"snuba api returned HTTP {exc.code} from {URL}", file=sys.stderr)
        return 1
    except urllib.error.URLError as exc:
        # urlopen() wraps connection-phase failures (refused, DNS, etc.) here.
        print(f"snuba api unreachable at {URL}: {exc.reason}", file=sys.stderr)
        return 1
    except TimeoutError:
        # A timeout firing during .read() (after urlopen returns) bubbles up
        # as a bare TimeoutError from the underlying socket — not wrapped in
        # URLError. Catch it explicitly so the message stays one-line.
        print(f"snuba api timed out reading {URL} after {TIMEOUT}s", file=sys.stderr)
        return 1
    except OSError as exc:
        # ConnectionResetError, etc. — anything else from the socket layer.
        print(f"snuba api error against {URL}: {exc}", file=sys.stderr)
        return 1

    if "ok" not in body:
        print(f"snuba api response missing 'ok' (from {URL}): {body!r}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
