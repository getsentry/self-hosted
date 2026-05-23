# Contributing to `self-hosted`

Hello! Thank you for considering to contribute to the `self-hosted` project. That itself means a lot for us.

This repository packages Sentry and its supporting services for self-hosted deployment. Changes that belong here are changes to the packaging and operating surface: Docker Compose wiring, install and upgrade scripts, default config templates, optional self-hosted patches, and tests for those workflows. If your fix only requires changing image contents rather than this repo's packaging, open or route it upstream and link that context in your issue or PR here.

Here's a list of the problem routing:

- Product behavior inside the Sentry application image usually belongs in [Sentry](https://github.com/getsentry/sentry) (especially if they're frontend changes).
- Event ingestion and light processing (PII scrubbing, etc) belongs in [Relay](https://github.com/getsentry/relay).
- Long-term event storage (any queries or insertion to ClickHouse) belongs in [Snuba](https://github.com/getsentry/snuba).
- Event symbolication of native symbols (Java, .NET, C, C++, etc.) belongs in [Symbolicator](https://github.com/getsentry/symbolicator).
- Uptime monitoring checks belongs in [Uptime Checker](https://github.com/getsentry/uptime-checker).
- Taskbroker, belongs in... [Taskbroker](https://github.com/getsentry/taskbroker) -- although I should clarify: this is for routing Sentry's tasks. We replaced Celery with this.
- Any Emerge Tools-related code (mobile build distributions, mobile size analysis, and mobile snapshots) belongs in [Launchpad](https://github.com/getsentry/launchpad).
- File/object storage proxy or management belongs in [Objectstore](https://github.com/getsentry/objectstore).

## What to contribute

Hi! I'm Reinaldy (aldy505), and I personally view self-hosted Sentry not just as something that we maintain, but as a community that we develop together. Contributing to self-hosted means more than just code contribution, there are lots of them!

1. Answer user issues, bug reports, and any requests via GitHub issues. It's easier to monitor it on the [Self-Hosted Sentry Projects pane](https://github.com/orgs/getsentry/projects/109/views/2), as it filters out issues that has the "Waiting For: Product Owner" label. Then it will remove the label once someone that has a minimum "Triage" access on the repository replied to the issue. This is a very nice & quick way to not get issues being forgotten. Although, I confess, there are issues that takes longer to reply as I need to regain a lot of context (if it's an old issue), or because I need to really take my time to browse & analyze the root cause.
2. Answer user issues (again), but on Discord channel! Usually this is the place to go if someone has a problem that blocks their self-hosted Sentry from running, as it's basically an instant messaging.
3. Write self-hosted related documentation on [sentry-docs](https://github.com/getsentry/sentry-docs/tree/master/develop-docs/self-hosted). The easiest way to do so is to put some writeup of [GitHub issues with "Category: Docs" label](https://github.com/getsentry/self-hosted/issues?q=is%3Aissue%20state%3Aopen%20label%3A%22Category%3A%20Docs%22), over to the `sentry-docs` repository.
4. Bump third-party dependencies (Postgres, Kafka, ClickHouse, etc) when a security patch arrives. Beware that we only upgrade the major version if SaaS (the cloud offering) does so, see the current versions on [`devservices/config.yml`](https://github.com/getsentry/sentry/blob/master/devservices/config.yml).
5. General improvements, that includes keeping feature flags in `sentry/sentry.conf.py` valid and in-check, ensuring no bugs is happening on the overall Bash scripts, and basically just make overall self-hosted experience better.

<!-- Everything below this is a draft. It will be changed. -->

## Contributor Checklist

1. Verify you are on a Linux environment with Bash. Although we don't limit users run this on Mac or WSL2, we don't recommend it nor we support for this kind of usecase.
2. Make sure Docker Engine is at least `19.03.6` and Docker Compose is at least `2.32.2`. Would be best if you're running the latest version.
3. Make sure Docker has enough resources. The default `feature-complete` profile expects roughly 4 CPUs and 16 GB RAM.
4. Clone the repo, review `.env`, and only add overrides in `.env.custom` unless you are intentionally changing defaults.
5. Run `./install.sh --skip-user-creation --no-report-self-hosted-issues` for a fast, repeatable local install.
6. Start the stack with `docker compose up --wait`.
7. Smoke test the install at `http://localhost:9000/auth/login/sentry/` or with `curl -f http://localhost:9000/_health/`.

The default external bind is port `9000` via `SENTRY_BIND=9000` in `.env`.

## Local Setup Basics

The install flow is driven by `./install.sh`, which performs version checks, copies example config files, generates missing secrets, builds any local images, and prepares the database. When the install completes, the expected next step is `docker compose up --wait`.

Generated and managed config lives in the repo working tree:

- `.env` is the default environment file.
- `.env.custom` is loaded automatically when present and should be your normal place for local overrides.
- `sentry/sentry.conf.py` is created from `sentry/sentry.conf.example.py`.
- `sentry/config.yml` is created from `sentry/config.example.yml`.
- `relay/config.yml` is created from `relay/config.example.yml`.
- `symbolicator/config.yml` is created from `symbolicator/config.example.yml`.

Treat those generated files as install outputs first and hand edits second. If you are changing generation logic, verify both the example file and the install script behavior.

## Daily Workflow

Keep the loop tight:

1. Change the packaging, install logic, config templates, or tests.
2. Re-run the narrowest useful validation.
3. Bring the stack up with `docker compose up --wait` if your change affects runtime behavior.
4. Verify the behavior from the running self-hosted instance.

Useful checks:

- Shell/unit-style checks: `CI=true ./unit-test.sh`
- Single shell test during iteration: `CI=true ./unit-test.sh _unit-test/<name>-test.sh`
- Pytest integration checks: install the Python 3.11 dev dependencies from `pyproject.toml`, then run `pytest _integration-test`
- Container health: `docker compose ps`
- App health: `curl -f http://localhost:9000/_health/`

The integration tests start the stack and create a test user automatically. If you are verifying manually, checking the login page, creating a user inside the `web` container, and exercising the exact changed path is usually enough for a first-pass sanity check.

When a change touches install or upgrade behavior, verify from a clean-ish state instead of only reusing old volumes. `./scripts/reset.sh` is the built-in destructive cleanup path for that.

## PR Expectations

Keep pull requests small enough that a reviewer can understand the full user impact in one pass. In this repo that usually means one packaging concern per PR: one install fix, one config migration, one test addition, or one optional modification.

Expectations:

- Include a clear problem statement, not just the fix.
- State whether the bug reproduces on a fresh install, upgrade, or both.
- Call out any generated files, config migrations, or operator-visible behavior changes.
- Include the exact validation you ran locally.
- Link upstream issues or PRs when the root cause is outside this repository.
- Keep commit history readable. A small number of focused commits is better than a long stream of fixups.

If you open an issue or PR, include enough context that someone unfamiliar with your machine can reproduce it: host OS, Docker and Compose versions, whether you used `.env.custom`, relevant `COMPOSE_PROFILES`, and the failing command or log excerpt.

## Troubleshooting

Common failures and first responses:

- Docker or Compose version check fails: upgrade first. `install.sh` enforces minimum versions.
- Docker daemon is not running or inaccessible: start Docker Desktop or the daemon, then retry.
- Permission errors talking to Docker on Linux: fix Docker socket/group access before debugging the repo.
- Git Bash on Windows: unsupported for install. Use WSL.
- Port `9000` already in use: change `SENTRY_BIND` in `.env.custom` and restart with `docker compose up --wait`.
- Install exits partway through: read the printed failing command, then inspect the generated `sentry_install_log-*.txt` log.
- A reused local state hides the bug: run `./scripts/reset.sh` and reinstall.
- Containers start but the app is unhealthy: run `docker compose ps`, then inspect the failing service with `docker compose logs <service>`.

Cleanup commands you will actually use:

- Stop services: `docker compose stop`
- Recreate and wait: `docker compose up --wait`
- Full local reset: `./scripts/reset.sh`

Use the destructive reset sparingly. It removes local containers, volumes, and locally built images for this stack.

## Getting Help

Use GitHub issues in this repository for packaging, install, upgrade, configuration-template, and self-hosted operational problems.

Route issues upstream when the failure is in the application or dependency itself rather than in how this repo assembles it. Examples: a Sentry web bug reproducible outside self-hosted packaging, a Relay validation bug, or a Snuba storage/query bug.

If you work at Sentry, route to the owning team for the affected upstream service when the repo change would only be a workaround. If you are unsure, file the issue here with your reproduction notes and say why you suspect an upstream dependency. That is enough context for triage.
