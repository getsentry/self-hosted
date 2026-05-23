# Contributing to `self-hosted`

Hello! Thank you for considering contributing to the `self-hosted` project. That means a lot to us.

This repository packages Sentry and its supporting services for self-hosted deployment. Changes that belong here are changes to the packaging and operating surface: Docker Compose wiring, install and upgrade scripts, default config templates, optional self-hosted patches, and tests for those workflows. If your fix only requires changing image contents rather than this repo's packaging, open or route it upstream and link that context in your issue or PR here.

Here's a list of where to route problems:

- Product behavior inside the Sentry application image usually belongs in [Sentry](https://github.com/getsentry/sentry) (especially if they're frontend changes).
- Event ingestion and light processing (PII scrubbing, etc) belongs in [Relay](https://github.com/getsentry/relay).
- Long-term event storage (any queries or insertion to ClickHouse) belongs in [Snuba](https://github.com/getsentry/snuba).
- Event symbolication of native symbols (Java, .NET, C, C++, etc.) belongs in [Symbolicator](https://github.com/getsentry/symbolicator).
- Uptime monitoring checks belongs in [Uptime Checker](https://github.com/getsentry/uptime-checker).
- Taskbroker belongs in [Taskbroker](https://github.com/getsentry/taskbroker). This is for routing Sentry's tasks; we replaced Celery with it.
- Any Emerge Tools-related code (mobile build distributions, mobile size analysis, and mobile snapshots) belongs in [Launchpad](https://github.com/getsentry/launchpad).
- File/object storage proxy or management belongs in [Objectstore](https://github.com/getsentry/objectstore).

## What to contribute

Hi! I'm Reinaldy (aldy505). I view self-hosted Sentry not just as something we maintain, but as a community we develop together. Contributing to self-hosted means more than code contributions; there are many ways to help!

1. Answer user issues, bug reports, and requests via GitHub issues. It's easier to monitor them on the [Self-Hosted Sentry Projects pane](https://github.com/orgs/getsentry/projects/109/views/2), which filters out issues with the "Waiting For: Product Owner" label. When someone with at least "Triage" access replies to the issue, the label will be removed. This helps prevent issues from being forgotten. Some issues may still take longer to reply to because they require regaining context or a deeper investigation.
2. Answer user issues on the Discord channel. This is usually the place to go if someone has a problem that prevents their self-hosted Sentry from running, since it's real-time messaging.
3. Write self-hosted documentation on [sentry-docs](https://github.com/getsentry/sentry-docs/tree/master/develop-docs/self-hosted). The easiest way is to transfer writeups of GitHub issues labeled "Category: Docs" to the `sentry-docs` repository.
4. Bump third-party dependencies (Postgres, Kafka, ClickHouse, etc.) when a security patch arrives. Note that we only upgrade a major version when SaaS (the cloud offering) does so; see current versions in [`devservices/config.yml`](https://github.com/getsentry/sentry/blob/master/devservices/config.yml).
5. General improvements, including keeping feature flags in `sentry/sentry.conf.py` valid, ensuring Bash scripts are free of bugs, and generally improving the self-hosted experience.

Any other contributions beyond those listed above are welcome!

## Local Setup Basics

> [!WARNING]
> Unless you have a very big machine, we don't recommend you to have a "local setup" on your own machine (your laptop or PC). We strongly recommend spawning a Linux virtual machine through a cloud provider or a controlled virtual environment (VirtualBox, Proxmox, etc.).

To get started, install these tools:
1. Docker Engine and Docker Compose (via Docker plugin system). Refer to [Docker Engine installation documentation](https://docs.docker.com/engine/install/). It's recommended to install via the distribution's package manager (`apt` for Debian/Ubuntu, and `dnf` or `yum` for CentOS/Fedora/RHEL).
2. Python v3.10 or higher.
3. the `uv` package manager. Refer to [their installation documentation](https://docs.astral.sh/uv/getting-started/installation/).
4. `prek` for Git pre-commit hooks. Refer to [their installation documentation](https://prek.j178.dev/installation/).

The install flow is driven by `./install.sh`, which performs version checks, copies example config files, generates missing secrets, builds any local images, and prepares the database. When the install completes, the expected next step is `docker compose up --wait`.

Generated and managed config files live in the repo working tree:

- `.env` is the default environment file.
- `.env.custom` is loaded automatically when present and should be your normal place for local overrides.
- `sentry/sentry.conf.py` is created from `sentry/sentry.conf.example.py`.
- `sentry/config.yml` is created from `sentry/config.example.yml`.
- `relay/config.yml` is created from `relay/config.example.yml`.
- `symbolicator/config.yml` is created from `symbolicator/config.example.yml`.

Treat those generated files as install outputs first and manual edits second. If you are changing generation logic, verify both the example file and the install script behavior.

## Testing

There are two kinds of tests:

1. Unit tests: run specific bash scripts and ensure they're working as intended. Test files are under the `_unit-test/` directory, and assertions are made using Bash.
2. Integration tests: run the entire self-hosted stack (using specific `COMPOSE_PROFILES`) by running `./install.sh` and `docker compose up -d`, then execute scenarios for logging in and verifying that events are ingested and queried correctly. Test files are under `_integration-test/`, and assertions are written in Python using the `pytest` testing framework.

Specifically for integration tests, dependencies are managed through `uv`. To set up the environment and install testing dependencies, run:

```sh
uv sync --frozen
```

Then, to run the integration tests, run:

```sh
uv run pytest -x --cov --junitxml=junit.xml _integration-test/
```

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

## Cutting Monthly Release

This section is not relevant to the general public; it provides an overview of what the release pipeline looks like. If you're an employee, refer to the [Notion doc](https://www.notion.so/sentry/Cutting-Monthly-Self-Hosted-Releases-fe5365a5f20d4ec9a530932b5931a2cf).

To perform a self-hosted release, you need to do the following things in order:
1. Release all components (sentry, snuba, relay, etc) through `.github/actions/release.{yaml,yml}` on each repository. It's triggered automatically every 15th of the month. You can also manually trigger it via "workflow dispatch".
2. It will trigger issue creation on the `getsentry/publish` repository; those issues need to be approved by adding the "accepted" label to each. If a CI check is red, retry the failing jobs and re-add the "accepted" label. If the CI checks are green, the release will be created.
3. After all components are released, release `self-hosted` using `.github/actions/release.yml` and approve it on the `publish` repository.
4. Optionally, update the release notes on the `self-hosted` repository to inform users about the changes.

## Getting Help

To get help on contributing, reach out to `#self-hosted` on Sentry's Discord.

If you're a Sentry employee, reach out to `#discuss-self-hosted` on Slack.
