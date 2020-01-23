# Sentry 10 On-Premise [![Build Status][build-status-image]][build-status-url]

Official bootstrap for running your own [Sentry](https://sentry.io/) with [Docker](https://www.docker.com/).

## Requirements

 * Docker 17.05.0+
 * Compose 1.19.0+

## Minimum Hardware Requirements:

 * You need at least 2400MB RAM

## Setup

To get started with all the defaults, simply clone the repo and run `./install.sh` in your local check-out.

There may need to be modifications to the included example config files (`sentry/config.example.yml` and `sentry/sentry.conf.example.py`) to accommodate your needs or your environment (such as adding GitHub credentials). If you want to perform these, do them before you run the install script and copy them without the `.example` extensions in the name (such as `sentry/sentry.conf.py`) before running the `install.sh` script.

The recommended way to customize your configuration is using the files below, in that order:

 * `config.yml`
 * `sentry.conf.py`
 * `.env` w/ environment variables

We currently support a very minimal set of environment variables to promote other means of configuration.

If you have any issues or questions, our [Community Forum](https://forum.sentry.io/c/on-premise) is at your service! Everytime you run the install script, it will generate a log file, `sentry_install_log-<ISO_TIMESTAMP>.txt` with the output. Sharing these logs would help people diagnose any issues you might be having.

## Event Retention

Sentry comes with a cleanup cron job that prunes events older than `90 days` by default. If you want to change that, you can change the `SENTRY_EVENT_RETENTION_DAYS` environment variable in `.env` or simply override it in your environment. If you do not want the cleanup cron, you can remove the `sentry-cleanup` service from the `docker-compose.yml`file.

## Securing Sentry with SSL/TLS

If you'd like to protect your Sentry install with SSL/TLS, there are
fantastic SSL/TLS proxies like [HAProxy](http://www.haproxy.org/)
and [Nginx](http://nginx.org/). You'll likely want to add this service to your `docker-compose.yml` file.

## Updating Sentry

The included `install.sh` script is meant to be idempotent and to bring you to the latest version. What this means is you can and should run `install.sh` to upgrade to the latest version available. Remember that the output of the script will be stored in a log file, `sentry_install_log-<ISO_TIMESTAMP>.txt`, which you may share for diagnosis if anything goes wrong.

## Resources

 * [Documentation](https://docs.sentry.io/server/)
 * [Bug Tracker](https://github.com/getsentry/onpremise/issues)
 * [Forums](https://forum.sentry.io/c/on-premise)
 * [Discord](https://discord.gg/mg5V76F) (Sentry Community, #sentry-server)


[build-status-image]: https://api.travis-ci.com/getsentry/onpremise.svg?branch=master
[build-status-url]: https://travis-ci.com/getsentry/onpremise
