import subprocess
import os
from functools import lru_cache
import requests
import unittest
import sentry_sdk
import time
import json

SENTRY_CONFIG_PY = "sentry/sentry.conf.py"
SENTRY_TEST_HOST = os.getenv("SENTRY_TEST_HOST", "http://localhost:9000")
TEST_USER = 'test@example.com'
TEST_PASS = 'test123TEST'

def run_shell_command(cmd, **kwargs) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, shell=True, check=True, **kwargs)

class IntegrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.session = requests.Session()
        for i in range(5):
            response = requests.get(SENTRY_TEST_HOST)
            if response.status_code == 200:
                break
            time.sleep(1)
        assert response.status_code == 200

        # Create test user
        run_shell_command(f"echo y | docker compose exec web sentry createuser --force-update --superuser --email {TEST_USER} --password {TEST_PASS}")

    def wait_for_event(self, request: str) -> requests.Response:
        for i in range(60):
            response = self.session.get(request,
                headers={'Referer': SENTRY_TEST_HOST}
            )
            if response.status_code == 200:
                break
            time.sleep(1)
        assert response.status_code == 200
        return response

    @lru_cache
    def get_sentry_dsn(self) -> str:
        response = self.session.get(f"{SENTRY_TEST_HOST}/api/0/projects/sentry/internal/keys/")
        sentry_dsn = json.loads(response.text)[0]["dsn"]["public"]
        return sentry_dsn

    def test_initial_redirect(self):
        initial_auth_redirect = self.session.get(SENTRY_TEST_HOST)
        assert initial_auth_redirect.url == f"{SENTRY_TEST_HOST}/auth/login/sentry/"

    def test_login(self):
        login_csrf_token = self.session.get(SENTRY_TEST_HOST).text.split('"csrfmiddlewaretoken" value="')[1].split('"')[0]
        login_response = self.session.post(f"{SENTRY_TEST_HOST}/auth/login/sentry/",
            data={'op': 'login', 'username': TEST_USER, 'password': TEST_PASS, 'csrfmiddlewaretoken': login_csrf_token},
            headers={'Referer': f"{SENTRY_TEST_HOST}/auth/login/sentry/"}
        )
        assert '"isAuthenticated":true' in login_response.text
        assert '"username":"test@example.com"' in login_response.text
        assert '"isSuperuser":true' in login_response.text
        assert login_response.cookies["sc"] is not None
        # Set up initial/required settings (InstallWizard request)
        self.session.headers.update({'X-CSRFToken': login_response.cookies['sc']})
        response = self.session.put(f"{SENTRY_TEST_HOST}/api/0/internal/options/?query=is:required",
            headers={'Referer':SENTRY_TEST_HOST},
            data={"mail.use-tls":False,"mail.username":"","mail.port":25,"system.admin-email":"ben@byk.im","mail.password":"","system.url-prefix":SENTRY_TEST_HOST,"auth.allow-registration":False,"beacon.anonymous":True}
        )

    def test_receive_event(self):
        event_id = None
        with sentry_sdk.init(dsn=self.get_sentry_dsn()):
            event_id = sentry_sdk.capture_exception(Exception("a failure"))
        assert event_id is not None
        response = self.wait_for_event(f"{SENTRY_TEST_HOST}/api/0/projects/sentry/internal/events/{event_id}/")
        response_json = json.loads(response.text)
        assert response_json['eventID'] == event_id
        assert response_json['metadata']['value'] == 'a failure'

    def test_cleanup_crons_running(self):
        cleanup_crons = run_shell_command("docker compose --ansi never ps -a | tee debug.log | grep -E -e '\\-cleanup\\s+running\\s+' -e '\\-cleanup[_-].+\\s+Up\\s+'", capture_output=True).stdout
        assert len(cleanup_crons) > 0

    def test_custom_cas(self):
        run_shell_command("source _integration-test/custom-ca-roots/setup.sh")
        run_shell_command("docker compose --ansi never run --no-deps web python3 /etc/sentry/test-custom-ca-roots.py")
        run_shell_command("source _integration-test/custom-ca-roots/teardown.sh")

    def test_receive_transaction_events(self):
        with sentry_sdk.init(dsn=self.get_sentry_dsn(), profiles_sample_rate=1.0, traces_sample_rate=1.0):
            def dummy_func():
                sum = 0
                for i in range(5):
                    sum += i
                    time.sleep(0.25)
            with sentry_sdk.start_transaction(op="task", name="Test Transactions"):
                dummy_func()
        profiles_response = self.wait_for_event(f"{SENTRY_TEST_HOST}/api/0/organizations/sentry/events/?dataset=profiles&field=profile.id&project=1&statsPeriod=1h")
        assert profiles_response.status_code == 200
        profiles_response_json = json.loads(profiles_response.text)
        assert len(profiles_response_json) > 0
        spans_response = self.wait_for_event(f"{SENTRY_TEST_HOST}/api/0/organizations/sentry/events/?dataset=spansIndexed&field=id&project=1&statsPeriod=1h")
        assert spans_response.status_code == 200
        spans_response_json = json.loads(spans_response.text)
        assert len(spans_response_json) > 0
