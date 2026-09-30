#!/usr/bin/env python3
"""
HTTP healthcheck for self-hosted services.

Usage: python3 /healthcheck/http.py <url>

GETs the URL and exits 0 if the response body contains "ok", else 1. On
failure, prints a one-line description to stderr rather than a full Python
traceback, so `docker inspect` output stays readable.

Uses only the standard library, so it works in any image with python3 on
PATH, including distroless ones. docker-compose.yml mounts this directory
read-only at /healthcheck.
"""

import sys
import urllib.error
import urllib.request

TIMEOUT = 2  # seconds


def main(url: str) -> int:
    try:
        body = urllib.request.urlopen(url, timeout=TIMEOUT).read().decode()
    except urllib.error.HTTPError as exc:
        print(f"HTTP {exc.code} from {url}", file=sys.stderr)
        return 1
    except urllib.error.URLError as exc:
        # urlopen() wraps connection-phase failures (refused, DNS, etc.) here.
        print(f"{url} unreachable: {exc.reason}", file=sys.stderr)
        return 1
    except TimeoutError:
        # A timeout firing during .read() (after urlopen returns) bubbles up
        # as a bare TimeoutError from the underlying socket — not wrapped in
        # URLError. Catch it explicitly so the message stays one-line.
        print(f"timed out reading {url} after {TIMEOUT}s", file=sys.stderr)
        return 1
    except OSError as exc:
        # ConnectionResetError, etc. — anything else from the socket layer.
        print(f"error against {url}: {exc}", file=sys.stderr)
        return 1

    if "ok" not in body:
        print(f"response from {url} missing 'ok': {body!r}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("usage: http.py <url>", file=sys.stderr)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
