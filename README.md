# Self-Hosted Sentry 22.9.0

Official bootstrap for running your own [Sentry](https://sentry.io/) with [Docker](https://www.docker.com/).

## Requirements

* Docker 19.03.6+
* Compose 1.28.0+
* 4 CPU Cores
* 8 GB RAM
* 20 GB Free Disk Space

## Setup

### Installation

To get started with all the defaults, simply clone the repo and run `./install.sh` in your local check-out. Please also read the section below about monitoring. Sentry uses Python 3 by default since December 4th, 2020 and Sentry 21.1.0 is the last version to support Python 2.

During the install, a prompt will ask if you want to create a user account. If you require that the install not be blocked by the prompt, run `./install.sh --skip-user-prompt`.

Thinking of not managing this yourself? Check out the [SaaS migration docs](https://docs.sentry.io/product/sentry-basics/migration/) or [contact us](https://sentry.io/from/self-hosted) for help.

Please visit [our documentation](https://develop.sentry.dev/self-hosted/) for everything else.

### Customize DotEnv (.env) file

Environment specific configurations can be done in the `.env.custom` file. It will be located in the root directory of the Sentry installation, and if it exists then `.env` will be ignored entirely.

By default, there exists no `.env.custom` file. In this case, you can manually add this file by copying the `.env` file to a new `.env.custom` file and adjust your settings in the `.env.custom` file.

Please keep in mind to check the `.env` file for changes, when you perform an upgrade of Sentry, so that you can adjust your `.env.custom` accordingly, if required, as `.env` is ignored entirely if `.env.custom` is present.

### Enhance Sentry image

To install plugins and their dependencies or make other modifications to the Sentry base image,
copy `sentry/enhance-image.example.sh` to `sentry/enhance-image.sh` and add necessary steps there.
For example, you can use `apt-get` to install dependencies and use `pip` to install plugins.

After making modifications to `sentry/enhance-image.sh`, run `./install.sh` again to apply them.

## Tips & Tricks

### Event Retention

Sentry comes with a cleanup cron job that prunes events older than `90 days` by default. If you want to change that, you can change the `SENTRY_EVENT_RETENTION_DAYS` environment variable in `.env` or simply override it in your environment. If you do not want the cleanup cron, you can remove the `sentry-cleanup` service from the `docker-compose.yml`file.

### Installing a specific SHA

If you want to install a specific release of Sentry, use the tags/releases on this repo.

We continuously push the Docker image for each commit made into [Sentry](https://github.com/getsentry/sentry), and other services such as [Snuba](https://github.com/getsentry/snuba) or [Symbolicator](https://github.com/getsentry/symbolicator) to [our Docker Hub](https://hub.docker.com/u/getsentry) and tag the latest version on master as `:nightly`. This is also usually what we have on sentry.io and what the install script uses. You can use a custom Sentry image, such as a modified version that you have built on your own, or simply a specific commit hash by setting the `SENTRY_IMAGE` environment variable to that image name before running `./install.sh`:

```shell
SENTRY_IMAGE=getsentry/sentry:83b1380 ./install.sh
```

Note that this may not work for all commit SHAs as this repository evolves with Sentry and its satellite projects. It is highly recommended to check out a version of this repository that is close to the timestamp of the Sentry commit you are installing.

### Using Linux

If you are using Linux and you need to use `sudo` when running `./install.sh`, make sure to place the environment variable *after* `sudo`:

```shell
sudo SENTRY_IMAGE=us.gcr.io/sentryio/sentry:83b1380 ./install.sh
```

Where you replace `83b1380` with the sha you want to use.

### Self-Hosted Monitoring

We'd love to catch errors in self-hosted so you don't run into them, and so we can fix them faster! When you run `./install.sh`, you will be prompted to select whether to opt in or out of our monitoring. If you opt into our monitoring, we will send information to our own self-hosted Sentry instance for development and debugging purposes. We may collect:

- OS username
- IP address
- install log
- runtime errors in Sentry
- performance data

Thirty (30) day retention. No marketing. Privacy policy at sentry.io/privacy.

Starting with the 22.10.0 release in October, we will require those running the Sentry installer to choose to opt in or out. If you are running the installer under automation, you may want to set `REPORT_SELF_HOSTED_ISSUES` or pass `--(no-)report-self-hosted-issues` to the installer accordingly.

