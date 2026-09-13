# AGENTS.md

## Project Overview

This repository is Sentry's self-hosted packaging. It bundles upstream Sentry images (Sentry, Relay, Snuba, Symbolicator, and others) into a Docker Compose deployment with install/upgrade scripts, config templates, and optional patches. This repo does **not** contain the application code itself — changes to product behavior belong in the upstream repositories (see `## Where Changes Belong`).

## Repository Layout

- `install.sh` — install/upgrade entrypoint. Sets shell strictness and sources the steps in `install/` in order. Run it, don't edit-and-run individual steps.
- `install/` — sourced install steps and helpers (`_lib.sh`, `parse-cli.sh`, `ensure-files-from-examples.sh`, `wrap-up.sh`, …). These are **not** standalone executables.
- `scripts/` — standalone operator scripts (`reset.sh`, `backup.sh`, `restore.sh`) plus Craft-driven release helpers.
- `docker-compose.yml`, `.env`, `*.example.*` — deployment source: Compose service wiring, shipped defaults, and config templates.
- `_unit-test/` — Bash assertion tests; `_integration-test/` — pytest end-to-end tests.
- `optional-modifications/patches/` — community patches ("plugin system") applied with `patch -p0`.
- `action.yaml`, `get-compose-action/` — the GitHub Action downstream repos use to run self-hosted E2E tests.
- Per-service dirs (`sentry/`, `relay/`, `snuba/`, `symbolicator/`, `taskbroker/`, `clickhouse/`, `geoip/`, `jq/`) — config templates, patches, and helper images for that service.
- `workstation/` and `sentry-admin.sh` are **unmaintained** — do not derive changes from them.

## Local Setup and Safety

The tools below are needed to run installs and tests, but are not hard requirements for every pull request.

- **Docker Engine + Docker Compose** (via the Docker plugin system). Install via your distribution's package manager (`apt` for Debian/Ubuntu, `dnf`/`yum` for CentOS/Fedora/RHEL).
- **Python >=3.11**
- **`uv`** package manager — see [uv installation docs](https://docs.astral.sh/uv/getting-started/installation/).
- **`prek`** for Git pre-commit hooks — see [prek installation docs](https://prek.j178.dev/installation/).

Install test dependencies with:

```sh
uv sync --frozen
```

> **WARNING: Do NOT run `./install.sh`, `./unit-test.sh`, or the integration tests on your laptop or personal workstation.** They require Docker plus a dedicated Linux VM with substantial resources, and they are destructive: `./unit-test.sh` calls `./scripts/reset.sh`, which runs `docker compose down --volumes --remove-orphans --rmi local` and deletes every `sentry-*` Docker volume. Only run them on a dedicated VM (cloud provider or controlled virtual environment like VirtualBox/Proxmox) or in CI.

## Running Tests

Both suites need Docker Engine, mutate local Docker state (containers, images, volumes), and clone the working copy into a `/tmp` sandbox via `_unit-test/_test_setup.sh`. Re-read the warning above before running either locally.

### Unit tests

```sh
CI=true ./unit-test.sh                      # whole suite
CI=true ./unit-test.sh _unit-test/error-handling-test.sh  # single file
DEBUG=1 CI=true ./unit-test.sh _unit-test/error-handling-test.sh  # keep the sandbox for debugging
```

`./unit-test.sh` exits early unless `CI=true` is set; it builds a `jq` image and runs each Bash assertion file matching `_unit-test/*-test.sh`. It does not start the full self-hosted stack. `_unit-test/error-handling-test.sh` additionally diffs a captured error envelope against `_unit-test/snapshots/sentry-envelope-<hash>` — if you change error-reporting output, update that snapshot deliberately instead of treating the diff as noise.

### Integration tests

```sh
uv run pytest -x --cov --junitxml=junit.xml _integration-test/
```

**Only run on the dedicated VM.** Integration tests execute `./install.sh` and `docker compose up --wait`, then verify event ingestion and querying. They require the full self-hosted stack running.

## Code Style and Conventions

### Bash

- `install.sh` is the entrypoint and sets `set -eEuo pipefail` plus `umask 002`. Files in `install/` are **sourced** by it: do not re-declare `set`/`umask`, and remember that a sourced `exit`/`return` aborts the entire install (only `parse-cli.sh` does this intentionally, for `--help`/bad flags). Failures are surfaced by the trap installed in `install/error-handling.sh`. Standalone `scripts/*.sh` set their own flags (e.g. `scripts/_lib.sh` uses `set -eEuo pipefail`, `scripts/bump-version.sh` uses `set -eu`).
- Reuse helpers in `install/_lib.sh` (`ensure_file_from_example`, `vergte`, …). New install steps must be sourced from `install.sh` in the right order.
- Wrap step output in `${_group}` … `${_endgroup}` (defined in `install/_lib.sh`) so GitHub Actions renders collapsible sections instead of polluting the log stream.
- Format and lint before committing: `prek run --all-files` (the `shfmt` hook runs `mvdan/shfmt` in a container). ShellCheck CI covers only `install/_lib.sh`, `scripts/**/*.sh`, `unit-test.sh`, `optional-modifications/**/*.sh`, and `workstation/**/*.sh` — other `install/*.sh` helpers are unchecked by CI, so keep them clean manually.

### Config files and patches

- Generated files are install outputs, not source of truth:
  - `sentry/sentry.conf.py` (from `sentry/sentry.conf.example.py`)
  - `sentry/config.yml` (from `sentry/config.example.yml`)
  - `relay/config.yml` (from `relay/config.example.yml`, created by `install/ensure-relay-credentials.sh`)
  - `symbolicator/config.yml` (from `symbolicator/config.example.yml`)
- Edits to example files must be mirrored in `install/ensure-files-from-examples.sh` or the relevant install step if generation logic changes.
- `.env` is **committed source**, not generated and not secret: it holds the shipped defaults (Compose profiles, image tags, ports, retention). Per-operator overrides belong in `.env.custom`, which is gitignored and takes precedence — `install/_lib.sh` sources `.env.custom` first, then `.env`. Do NOT gitignore `.env` or treat its contents as install output.
- `optional-modifications/patches/**/*.patch` are excluded from pre-commit and apply to `.env`, `docker-compose.yml`, and `*.example.*` via `patch -p0`. If you edit any of those targets, verify the patches still apply and refresh them with `diff -Naru` (see `optional-modifications/README.md`).

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
- Ask the user to write the PR description and problem statement in their own words; guide them on how to write it, but do not write it for them.
- The PR template at `.github/PULL_REQUEST_TEMPLATE.md` contains a legal boilerplate that must remain intact and can only be confirmed by the actual contributor.

## Downstream Consumers and Release Tooling

- `action.yaml` / `get-compose-action/` define the GitHub Action that other Sentry repos use to run self-hosted E2E tests against their own images (relay, snuba, symbolicator, taskbroker, uptime-checker, vroom). Its inputs (`project_name`, `image_url`, `compose_profiles`, `skip_backup_restore_test`, …) are a public interface — do not rename or remove inputs without coordinating with those consumers, and keep default behavior backward compatible.
- Releases are driven by [Craft](https://github.com/getsentry/craft) via `.craft.yml` (calver versioning): Craft runs `scripts/bump-version.sh` pre-release and `scripts/post-release.sh` post-release, and generates `CHANGELOG.md`. Do NOT hand-edit `CHANGELOG.md`, invoke those scripts manually, or hand-bump the `*_IMAGE` tags in `.env` — versioning belongs to the release pipeline.

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
