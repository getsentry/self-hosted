import os
import subprocess
import time

import httpx
import pytest

SENTRY_CONFIG_PY = "sentry/sentry.conf.py"
SENTRY_TEST_HOST = os.getenv("SENTRY_TEST_HOST", "http://localhost:9000")
TEST_USER = "test@example.com"
TEST_PASS = "test123TEST"
TIMEOUT_SECONDS = 60


def pytest_addoption(parser):
    parser.addoption("--customizations", default="disabled")


@pytest.fixture(scope="session", autouse=True)
def configure_self_hosted_environment(request):
    subprocess.run(
        ["docker", "compose", "--ansi", "never", "up", "-d"],
        check=True,
        capture_output=True,
    )
    for i in range(TIMEOUT_SECONDS):
        try:
            response = httpx.get(SENTRY_TEST_HOST, follow_redirects=True)
        except httpx.RequestError:
            time.sleep(1)
        else:
            if response.status_code == 200:
                break
    else:
        raise AssertionError("timeout waiting for self-hosted to come up")

    if request.config.getoption("--customizations") == "enabled":
        os.environ["TEST_CUSTOMIZATIONS"] = "enabled"
        script_content = """\
#!/bin/bash
touch /created-by-enhance-image
apt-get update
apt-get install -y gcc libsasl2-dev python-dev-is-python3 libldap2-dev libssl-dev
"""

        with open("sentry/enhance-image.sh", "w") as script_file:
            script_file.write(script_content)
        # Set executable permissions for the shell script
        os.chmod("sentry/enhance-image.sh", 0o755)

        # Write content to the requirements.txt file
        with open("sentry/requirements.txt", "w") as req_file:
            req_file.write("python-ldap\n")
        os.environ["MINIMIZE_DOWNTIME"] = "1"
        subprocess.run(["./install.sh"], check=True, capture_output=True)
    # Create test user
    subprocess.run(
        [
            "docker",
            "compose",
            "exec",
            "-T",
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


@pytest.fixture()
def setup_backup_restore_env_variables():
    os.environ["SENTRY_DOCKER_IO_DIR"] = os.path.join(os.getcwd(), "sentry")
    os.environ["SKIP_USER_CREATION"] = "1"
