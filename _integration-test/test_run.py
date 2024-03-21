import subprocess
import os
from functools import lru_cache
from bs4 import BeautifulSoup
import httpx
import pytest
import sentry_sdk
import time
import json
import re
from typing import Callable

SENTRY_CONFIG_PY = "sentry/sentry.conf.py"
SENTRY_TEST_HOST = os.getenv("SENTRY_TEST_HOST", "http://localhost:9000")
TEST_USER = "test@example.com"
TEST_PASS = "test123TEST"
TIMEOUT_SECONDS = 60


def poll_for_response(
    request: str, client: httpx.Client, validator: Callable = None
) -> httpx.Response:
    for i in range(TIMEOUT_SECONDS):
        response = client.get(
            request, follow_redirects=True, headers={"Referer": SENTRY_TEST_HOST}
        )
        if response.status_code == 200:
            if validator is None or validator(response.text):
                break
        time.sleep(1)
    else:
        raise AssertionError(
            "timeout waiting for response status code 200 or valid data"
        )
    return response


@lru_cache
def get_sentry_dsn(client: httpx.Client) -> str:
    response = poll_for_response(
        f"{SENTRY_TEST_HOST}/api/0/projects/sentry/internal/keys/",
        client,
        lambda x: len(json.loads(x)[0]["dsn"]["public"]) > 0,
    )
    sentry_dsn = json.loads(response.text)[0]["dsn"]["public"]
    return sentry_dsn


@pytest.fixture()
def client_login():
    client = httpx.Client()
    response = client.get(SENTRY_TEST_HOST, follow_redirects=True)
    parser = BeautifulSoup(response.text, "html.parser")
    login_csrf_token = parser.find("input", {"name": "csrfmiddlewaretoken"})["value"]
    login_response = client.post(
        f"{SENTRY_TEST_HOST}/auth/login/sentry/",
        follow_redirects=True,
        data={
            "op": "login",
            "username": TEST_USER,
            "password": TEST_PASS,
            "csrfmiddlewaretoken": login_csrf_token,
        },
        headers={"Referer": f"{SENTRY_TEST_HOST}/auth/login/sentry/"},
    )
    assert login_response.status_code == 200
    yield (client, login_response)


def test_initial_redirect():
    initial_auth_redirect = httpx.get(SENTRY_TEST_HOST, follow_redirects=True)
    assert initial_auth_redirect.url == f"{SENTRY_TEST_HOST}/auth/login/sentry/"


def test_login(client_login):
    client, login_response = client_login
    parser = BeautifulSoup(login_response.text, "html.parser")
    script_tag = parser.find(
        "script", string=lambda x: x and "window.__initialData" in x
    )
    assert script_tag is not None
    json_data = json.loads(script_tag.text.split("=", 1)[1].strip().rstrip(";"))
    assert json_data["isAuthenticated"] is True
    assert json_data["user"]["username"] == "test@example.com"
    assert json_data["user"]["isSuperuser"] is True
    assert login_response.cookies["sc"] is not None
    # Set up initial/required settings (InstallWizard request)
    client.headers.update({"X-CSRFToken": login_response.cookies["sc"]})
    response = client.put(
        f"{SENTRY_TEST_HOST}/api/0/internal/options/?query=is:required",
        follow_redirects=True,
        headers={"Referer": SENTRY_TEST_HOST},
        data={
            "mail.use-tls": False,
            "mail.username": "",
            "mail.port": 25,
            "system.admin-email": "test@example.com",
            "mail.password": "",
            "system.url-prefix": SENTRY_TEST_HOST,
            "auth.allow-registration": False,
            "beacon.anonymous": True,
        },
    )
    assert response.status_code == 200


def test_receive_event(client_login):
    event_id = None
    client, _ = client_login
    with sentry_sdk.init(dsn=get_sentry_dsn(client)):
        event_id = sentry_sdk.capture_exception(Exception("a failure"))
    assert event_id is not None
    response = poll_for_response(
        f"{SENTRY_TEST_HOST}/api/0/projects/sentry/internal/events/{event_id}/", client
    )
    response_json = json.loads(response.text)
    assert response_json["eventID"] == event_id
    assert response_json["metadata"]["value"] == "a failure"


def test_cleanup_crons_running():
    docker_services = subprocess.check_output(
        [
            "docker",
            "compose",
            "--ansi",
            "never",
            "ps",
            "-a",
        ],
        text=True,
    )
    pattern = re.compile(
        r"(\-cleanup\s+running)|(\-cleanup[_-].+\s+Up\s+)", re.MULTILINE
    )
    cleanup_crons = pattern.findall(docker_services)
    assert len(cleanup_crons) > 0


def test_custom_cas():
    try:
        subprocess.run(["./_integration-test/custom-ca-roots/setup.sh"], check=True)
        subprocess.run(
            ["docker", "compose", "--ansi", "never", "run", "--no-deps", "web", "python3", "/etc/sentry/test-custom-ca-roots.py"], check=True
        )
    finally:
        subprocess.run(["./_integration-test/custom-ca-roots/teardown.sh"], check=True)


def test_receive_transaction_events(client_login):
    client, _ = client_login
    with sentry_sdk.init(
        dsn=get_sentry_dsn(client), profiles_sample_rate=1.0, traces_sample_rate=1.0
    ):

        def placeholder_fn():
            sum = 0
            for i in range(5):
                sum += i
                time.sleep(0.25)

        with sentry_sdk.start_transaction(op="task", name="Test Transactions"):
            placeholder_fn()
    poll_for_response(
        f"{SENTRY_TEST_HOST}/api/0/organizations/sentry/events/?dataset=profiles&field=profile.id&project=1&statsPeriod=1h",
        client,
        lambda x: len(json.loads(x)["data"]) > 0,
    )
    poll_for_response(
        f"{SENTRY_TEST_HOST}/api/0/organizations/sentry/events/?dataset=spansIndexed&field=id&project=1&statsPeriod=1h",
        client,
        lambda x: len(json.loads(x)["data"]) > 0,
    )
