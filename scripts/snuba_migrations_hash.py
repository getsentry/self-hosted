#!/usr/bin/env python3
"""
Compute a stable hash of snuba's migration set: the sorted list of
migration files under snuba/snuba_migrations/ plus the body of the
Topic(Enum) class in snuba/utils/streams/topics.py.

Used by the integration test action to key the docker volume cache.
Prints the hex digest on stdout.
"""

import glob
import hashlib
import re
import sys


def main() -> int:
    files = sorted(glob.glob("snuba/snuba_migrations/**/*.py", recursive=True))
    payload = "\n".join(files) + "\n"

    with open("snuba/utils/streams/topics.py") as f:
        src = f.read()
    match = re.search(r"(?<=class Topic\(Enum\):\n).+?(?=\n\n\n)", src, re.DOTALL)
    if match:
        payload += match.group(0)

    print(hashlib.md5(payload.encode()).hexdigest())
    return 0


if __name__ == "__main__":
    sys.exit(main())
