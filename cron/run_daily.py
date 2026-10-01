"""Run a command every day at midnight, container local time.

Usage: python3 /cron/run_daily.py <command> [args...]
"""

import datetime
import subprocess
import sys
import time


def next_midnight(now: datetime.datetime) -> datetime.datetime:
    tomorrow = now + datetime.timedelta(days=1)
    return tomorrow.replace(hour=0, minute=0, second=0, microsecond=0)


def main(command: list[str]) -> None:
    while True:
        run_at = next_midnight(datetime.datetime.now())
        print(f"Next run of `{' '.join(command)}` at {run_at:%Y-%m-%d %H:%M}", flush=True)
        # Re-check the wall clock every minute, like cron, so clock changes
        # and host suspends don't delay the run.
        while (remaining := (run_at - datetime.datetime.now()).total_seconds()) > 0:
            time.sleep(min(remaining, 60))
        result = subprocess.run(command)
        if result.returncode != 0:
            print(f"`{' '.join(command)}` exited with {result.returncode}", flush=True)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: run_daily.py <command> [args...]", file=sys.stderr)
        sys.exit(2)
    main(sys.argv[1:])
