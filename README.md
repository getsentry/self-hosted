# Self-Hosted Sentry 20.10.1

Official bootstrap for running your own [Sentry](https://sentry.io/) with [Docker](https://www.docker.com/).

## Requirements

 * Docker 19.03.6+
 * Compose 1.24.1+

## Minimum Hardware Requirements:

 * You need at least 2400MB RAM

## Setup

To get started with all the defaults, simply clone the repo and run `./install.sh` in your local check-out.

_If you like trying out new things, you can run `SENTRY_PYTHON3=1 ./install.sh` instead to use our brand new Python 3 images. **Keep in mind that Python 3 support is experimental at this point**_

During the install, a prompt will ask if you want to create a user account. If you require that the install not be blocked by the prompt, run `./install.sh --no-user-prompt`.

There may need to be modifications to the included example config files (`sentry/config.example.yml` and `sentry/sentry.conf.example.py`) to accommodate your needs or your environment (such as adding GitHub credentials). If you want to perform these, do them before you run the install script and copy them without the `.example` extensions in the name (such as `sentry/sentry.conf.py`) before running the `install.sh` script.

The recommended way to customize your configuration is using the files below, in that order:

 * `config.yml`
 * `sentry.conf.py`
 * `.env` w/ environment variables

We currently support a very minimal set of environment variables to promote other means of configuration.

If you have any issues or questions, our [Community Forum](https://forum.sentry.io/c/on-premise) is at your service! Everytime you run the install script, it will generate a log file, `sentry_install_log-<ISO_TIMESTAMP>.txt` with the output. Sharing these logs would help people diagnose any issues you might be having.

## Versioning

If you want to install a specific release of Sentry, use the tags/releases on this repo.

We continously push the Docker image for each commit made into [Sentry](https://github.com/getsentry/sentry), and other services such as [Snuba](https://github.com/getsentry/snuba) or [Symbolicator](https://github.com/getsentry/symbolicator) to [our Docker Hub](https://hub.docker.com/u/getsentry) and tag the latest version on master as `:nightly`. This is also usually what we have on sentry.io and what the install script uses. You can use a custom Sentry image, such as a modified version that you have built on your own, or simply a specific commit hash by setting the `SENTRY_IMAGE` environment variable to that image name before running `./install.sh`:

```shell
SENTRY_IMAGE=getsentry/sentry:83b1380 ./install.sh
```

Note that this may not work for all commit SHAs as this repository evolves with Sentry and its satellite projects. It is highly recommended to check out a version of this repository that is close to the timestamp of the Sentry commit you are installing.

## Event Retention

Sentry comes with a cleanup cron job that prunes events older than `90 days` by default. If you want to change that, you can change the `SENTRY_EVENT_RETENTION_DAYS` environment variable in `.env` or simply override it in your environment. If you do not want the cleanup cron, you can remove the `sentry-cleanup` service from the `docker-compose.yml`file.

## Securing Sentry with SSL/TLS

If you'd like to protect your Sentry install with SSL/TLS, there are
fantastic SSL/TLS proxies like [HAProxy](http://www.haproxy.org/)
and [Nginx](http://nginx.org/). Our recommendation is running and external Nginx instance or your choice of load balancer that does the TLS termination and more. Read more over at our [productionalizing self-hosted docs](https://develop.sentry.dev/self-hosted/#productionalizing).

## Updating Sentry

_You need to be on at least Sentry 9.1.2 to be able to upgrade automatically to the latest version. If you are not, upgrade to 9.1.2 first by checking out the [9.1.2 tag](https://github.com/getsentry/onpremise/tree/9.1.2) on this repo._

The included `install.sh` script is meant to be idempotent and to bring you to the latest version. What this means is you can and should run `install.sh` to upgrade to the latest version available. Remember that the output of the script will be stored in a log file, `sentry_install_log-<ISO_TIMESTAMP>.txt`, which you may share for diagnosis if anything goes wrong.

Also make sure to check for any difference between the example config files and your current config files in use. There might be new configuration that has to be added to your adjusted files. E.g. feature flags or server configuration.

For more information regarding updating your Sentry installation, please visit [our documentation](https://develop.sentry.dev/self-hosted/#upgrading).

## Resources

 * [Documentation](https://develop.sentry.dev/self-hosted/)
 * [Bug Tracker](https://github.com/getsentry/onpremise/issues)
 * [Community Forums](https://forum.sentry.io/c/on-premise)


[build-status-image]: https://github.com/getsentry/onpremise/workflows/test/badge.svg
[build-status-url]: https://git.io/JUYkh
