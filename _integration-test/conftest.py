import subprocess
import os
import time
import httpx
import pytest

SENTRY_CONFIG_PY = "sentry/sentry.conf.py"
SENTRY_TEST_HOST = os.getenv("SENTRY_TEST_HOST", "http://localhost:9000")
TEST_USER = "test@example.com"
TEST_PASS = "test123TEST"
TIMEOUT_SECONDS = 60


@pytest.fixture(scope="session", autouse=True)
def configure_self_hosted_environment():
    subprocess.run(["docker", "compose", "--ansi", "never", "up", "-d"], check=True)
    for i in range(TIMEOUT_SECONDS):
        try:
            response = httpx.get(SENTRY_TEST_HOST, follow_redirects=True)
        except httpx.ConnectionError:
            time.sleep(1)
        else:
            if response.status_code == 200:
                break
    else:
        raise AssertionError("timeout waiting for self-hosted to come up")

    # Create test user
    subprocess.run(
        [
            "docker",
            "compose",
            "exec",
            "web",
            "sentry",
            "createuser",
            "--force-update",
            "--superuser",
            "--email",
            TEST_USER,
            "--password",
            TEST_PASS,
            "--no-input",
        ],
        check=True,
        text=True,
    )
