# Self-Hosted Sentry Patches

Other than the default self-hosted Sentry installation, sometimes users can leverage their existing infrastructure to help them
with limited resources. "Patches", or you might call this like a "plugin system", is a collection of bash scripts that can be used
to modify the existing configuration to achieve the desired goal.

> [!WARNING]
> Beware that this is very experimental and might not work as expected.
>
> **Use it at your own risk!**

## How to use patches

The patches are designed mostly to help modify the existing configuration files. You will need to run the `install.sh` script afterwards. 
They should be run from the root directory. For example, the `external-kafka.sh` patch should be run as:
```bash
./patches/external-kafka.sh
```

Some patches might require additional steps to be taken, like providing credentials or additional TLS certificates.

## Official support

Sentry employees are not obliged to provide dedicated support for patches, but they can help by providing information to move us forward. We encourage the community to contribute for any bug fixes or improvements.

See the [support policy for self-hosted Sentry](https://develop.sentry.dev/self-hosted/support/) for more information.
