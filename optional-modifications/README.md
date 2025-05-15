# Optional Modifications

Other than the default self-hosted Sentry installation, sometimes users
can leverage their existing infrastructure to help them with limited
resources. "Patches", or you might call this like a "plugin system", is
a collection of patch files (see [man patch(1)](https://man7.org/linux/man-pages/man1/patch.1.html))
that can be used with to modify the existing configuration to achieve
the desired goal.

> [!WARNING]
> Beware that this is very experimental and might not work as expected.
>
> **Use it at your own risk!**

## How to use patches

The patches are designed mostly to help modify the existing
configuration files. You will need to run the `install.sh` script
afterwards.

They should be run from the root directory. For example, the
`external-kafka` patches should be run as:

```bash
patch < optional-modifications/patches/external-kafka/.env.patch
patch < optional-modifications/patches/external-kafka/config.example.yml.patch
patch < optional-modifications/patches/external-kafka/sentry.conf.example.py.patch
patch < optional-modifications/patches/external-kafka/docker-compose.yml.patch
```

Some patches might require additional steps to be taken, like providing
credentials or additional TLS certificates.

## Official support

Sentry employees are not obliged to provide dedicated support for
patches, but they can help by providing information to move us forward.
We encourage the community to contribute for any bug fixes or
improvements.

See the [support policy for self-hosted Sentry](https://develop.sentry.dev/self-hosted/support/) for more information.
