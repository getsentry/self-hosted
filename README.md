# Self-Hosted Sentry nightly

Official bootstrap for running your own [Sentry](https://sentry.io/) with [Docker](https://www.docker.com/).

## Requirements

 * Docker 19.03.6+
 * Compose 1.24.1+
 * 4 CPU Cores
 * 8 GB RAM
 * 20 GB Free Disk Space

## Setup

To get started with all the defaults, simply clone the repo and run `./install.sh` in your local check-out. Sentry uses Python 3 by default since December 4th, 2020 and Sentry 21.1.0 is the last version to support Python 2.

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

### Using Linux

If you are using Linux and you need to use `sudo` when running `./install.sh`, modifying the version of Sentry is slightly different. First, run the following:
```shell
sudo visudo
```
Then add the following line:
```shell
Defaults  env_keep += "SENTRY_IMAGE"
```
Save the file then in your terminal run the following

```shell
export SENTRY_IMAGE=us.gcr.io/sentryio/sentry:83b1380
sudo ./install.sh
```
Where you replace `83b1380` with the sha you want to use.

## Event Retention

Sentry comes with a cleanup cron job that prunes events older than `90 days` by default. If you want to change that, you can change the `SENTRY_EVENT_RETENTION_DAYS` environment variable in `.env` or simply override it in your environment. If you do not want the cleanup cron, you can remove the `sentry-cleanup` service from the `docker-compose.yml`file.

## Securing Sentry with SSL/TLS

If you'd like to protect your Sentry install with SSL/TLS, there are
fantastic SSL/TLS proxies like [HAProxy](http://www.haproxy.org/)
and [Nginx](http://nginx.org/). Our recommendation is running an external Nginx instance or your choice of load balancer that does the TLS termination and more. Read more over at our [productionalizing self-hosted docs](https://develop.sentry.dev/self-hosted/#productionalizing).

## Updating Sentry

_You need to be on at least Sentry 9.1.2 to be able to upgrade automatically to the latest version. If you are not, upgrade to 9.1.2 first by checking out the [9.1.2 tag](https://github.com/getsentry/onpremise/tree/9.1.2) on this repo._

We recommend (and sometimes require) you to upgrade Sentry one version at a time. That means if you are running 20.6.0, instead of going directly to 20.8.0, first go through 20.7.0. Skipping versions would work most of the time, but there will be times that we require you to stop at specific versions to ensure essential data migrations along the way.

Pull the version of the repository that you wish to upgrade to by checking out the tagged release of this repo. Make sure to check for any difference between the example config files and your current config files in use. There might be new configuration that has to be added to your adjusted files such as feature flags or server configuration.

The included `install.sh` script is meant to be idempotent and to bring you to the latest version. What this means is you can and should run `install.sh` to upgrade to the latest version available. Remember that the output of the script will be stored in a log file, `sentry_install_log-<ISO_TIMESTAMP>.txt`, which you may share for diagnosis if anything goes wrong.

For more information regarding updating your Sentry installation, please visit [our documentation](https://develop.sentry.dev/self-hosted/#upgrading).

## Resources

 * [Documentation](https://develop.sentry.dev/self-hosted/)
 * [Bug Tracker](https://github.com/getsentry/onpremise/issues)
 * [Community Forums](https://forum.sentry.io/c/on-premise)


[build-status-image]: https://github.com/getsentry/onpremise/workflows/test/badge.svg
[build-status-url]: https://git.io/JUYkh
