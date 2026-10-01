"""Run a command every day at midnight, container local time.

Usage: python3 /cron/run_daily.py <command> [args...]

A run still going at the next midnight is stopped before the next one starts,
so a stuck run can't block the schedule and runs never overlap.
"""

import datetime
import os
import signal
import subprocess
import sys
import time

STOP_GRACE_SECONDS = 60

current: subprocess.Popen[bytes] | None = None


def next_midnight(now: datetime.datetime) -> datetime.datetime:
    tomorrow = now + datetime.timedelta(days=1)
    return tomorrow.replace(hour=0, minute=0, second=0, microsecond=0)


def seconds_until(when: datetime.datetime) -> float:
    return (when - datetime.datetime.now()).total_seconds()


def stop(proc: subprocess.Popen[bytes]) -> None:
    # The run is its own process group, so this also reaches its workers.
    os.killpg(proc.pid, signal.SIGTERM)
    try:
        proc.wait(timeout=STOP_GRACE_SECONDS)
    except subprocess.TimeoutExpired:
        os.killpg(proc.pid, signal.SIGKILL)
        proc.wait()


def on_sigterm(signum: int, frame: object) -> None:
    if current is not None and current.poll() is None:
        stop(current)
    sys.exit(0)


def main(command: list[str]) -> None:
    global current
    signal.signal(signal.SIGTERM, on_sigterm)
    run_at = next_midnight(datetime.datetime.now())
    while True:
        print(f"Next run of `{' '.join(command)}` at {run_at:%Y-%m-%d %H:%M}", flush=True)
        # Check the wall clock every minute, like cron, so clock changes and
        # host suspends don't delay the run.
        while (remaining := seconds_until(run_at)) > 0:
            time.sleep(min(remaining, 60))

        deadline = next_midnight(run_at)
        current = subprocess.Popen(command, start_new_session=True)
        while current.poll() is None and (remaining := seconds_until(deadline)) > 0:
            time.sleep(min(remaining, 60))
        if current.poll() is None:
            print(f"`{' '.join(command)}` still running at the next scheduled run, stopping it", flush=True)
            stop(current)
        if current.returncode != 0:
            print(f"`{' '.join(command)}` exited with {current.returncode}", flush=True)
        run_at = deadline


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: run_daily.py <command> [args...]", file=sys.stderr)
        sys.exit(2)
    main(sys.argv[1:])
