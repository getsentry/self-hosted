# AGENTS.md

## Project Overview

This repository is Sentry's self-hosted packaging. It bundles upstream Sentry images (Sentry, Relay, Snuba, Symbolicator, and others) into a Docker Compose deployment with install/upgrade scripts, config templates, and optional patches. This repo does **not** contain the application code itself — changes to product behavior belong in the upstream repositories (see `## Where Changes Belong`).

## Local Setup and Safety

Prerequisites:

- **Docker Engine + Docker Compose** (via the Docker plugin system). Install via your distribution's package manager (`apt` for Debian/Ubuntu, `dnf`/`yum` for CentOS/Fedora/RHEL).
- **Python >=3.11**
- **`uv`** package manager — see [uv installation docs](https://docs.astral.sh/uv/getting-started/installation/).
- **`prek`** for Git pre-commit hooks — see [prek installation docs](https://prek.j178.dev/installation/).

Install test dependencies with:

```sh
uv sync --frozen
```

> **WARNING: Do NOT run `./install.sh` on your laptop or personal workstation.** The full install and integration test stack requires a dedicated Linux VM with substantial resources. Only run it on a dedicated VM (cloud provider or controlled virtual environment like VirtualBox/Proxmox).

## Running Tests

### Unit tests

```sh
./unit-test.sh
```

Bash assertions under `_unit-test/`. These run locally and require no Docker infrastructure.

### Integration tests

```sh
uv run pytest -x --cov --junitxml=junit.xml _integration-test/
```

**Only run on the dedicated VM.** Integration tests execute `./install.sh` and `docker compose up --wait`, then verify event ingestion and querying. They require the full self-hosted stack running.

## Code Style and Conventions

- Install scripts are Bash. Follow the existing `set -eEuo pipefail` pattern and reuse helpers in `install/_lib.sh`.
- Generated files are install outputs, not source of truth:
  - `sentry/sentry.conf.py` (from `sentry/sentry.conf.example.py`)
  - `sentry/config.yml` (from `sentry/config.example.yml`)
  - `relay/config.yml` (from `relay/config.example.yml`)
  - `symbolicator/config.yml` (from `symbolicator/config.example.yml`)
  - `.env`
- Edits to example files must be mirrored in `install/ensure-files-from-examples.sh` or the relevant install step if generation logic changes.

## Pull Request Guidance

See `CONTRIBUTING.md` for the authoritative source.

- Keep PRs small: one packaging concern at a time (one install fix, one config migration, one test, etc.).
- Include a clear problem statement, not just the fix.
- State whether the bug reproduces on a fresh install, upgrade, or both.
- Call out any generated files, config migrations, or operator-visible behavior changes.
- Include the exact validation you ran locally.
- Link upstream issues or PRs when the root cause is outside this repository.

## Review Before You Submit

AI assistance is welcome, but the human opening the PR is responsible for the diff.

- Review every generated change, understand what it does, and make sure it matches the project's intent.
- Write the PR description and problem statement in your own words; do not copy-paste raw LLM output.
- The PR template at `.github/PULL_REQUEST_TEMPLATE.md` contains a legal boilerplate that must remain intact and can only be confirmed by the actual contributor.

## Where Changes Belong

This repo owns packaging and operating surface. Product bugs belong upstream:

| Problem area | Upstream repo |
|---|---|
| Sentry application behavior (especially frontend) | [getsentry/sentry](https://github.com/getsentry/sentry) |
| Event ingestion, PII scrubbing, etc. | [getsentry/relay](https://github.com/getsentry/relay) |
| Long-term event storage / ClickHouse queries | [getsentry/snuba](https://github.com/getsentry/snuba) |
| Native symbolication (Java, .NET, C, C++) | [getsentry/symbolicator](https://github.com/getsentry/symbolicator) |
| Uptime monitoring checks | [getsentry/uptime-checker](https://github.com/getsentry/uptime-checker) |
| Task routing (replaced Celery) | [getsentry/taskbroker](https://github.com/getsentry/taskbroker) |
| Mobile build distributions / size analysis / snapshots | [getsentry/launchpad](https://github.com/getsentry/launchpad) |
| File/object storage proxy or management | [getsentry/objectstore](https://github.com/getsentry/objectstore) |
