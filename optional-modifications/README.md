# Optional Modifications

While the default self-hosted Sentry installation is often sufficient, there are instances where leveraging existing infrastructure becomes a practical necessity, particularly for users with limited resources. This is where **patches**, or what can be understood as a **plugin system**, come into play.

A patch system comprises a collection of patch files (refer to man patch(1) for detailed information) designed to modify an existing Sentry configuration. This allows for targeted adjustments to achieve specific operational goals, optimizing Sentry's functionality within your current environment. This approach provides a flexible alternative to a full, customized re-installation, enabling users to adapt Sentry to their specific needs with greater efficiency.

We also actively encourage the community to contribute! If you've developed a patch that enhances your self-hosted Sentry experience, consider submitting a pull request. Your contributions can be invaluable to other users facing similar challenges, fostering a collaborative environment where shared solutions benefit everyone.

> [!WARNING]
> Beware that this is very experimental and might not work as expected.
>
> **Use it at your own risk!**

## How to use patches

The patches are designed mostly to help modify the existing configuration files. You will need to run the `install.sh` script afterwards.

They should be run from the root directory. For example, the `external-kafka` patches should be run as:

```bash
patch -p0 < optional-modifications/patches/external-kafka/.env.patch
patch -p0 < optional-modifications/patches/external-kafka/config.example.yml.patch
patch -p0 < optional-modifications/patches/external-kafka/sentry.conf.example.py.patch
patch -p0 < optional-modifications/patches/external-kafka/docker-compose.yml.patch
```

The `-p0` flag is important to ensure the patch applies to the correct absolute file path.

Some patches might require additional steps to be taken, like providing credentials or additional TLS certificates. Make sure to see your changed files before running the `install.sh` script.

## How to create patches

1. Copy the original file to a temporary file name. For example, if you want to create a `clustered-redis` patch, you might want to copy `docker-compose.yml` to `docker-compose.clustered-redis.yml`.
2. Make your changes on the `docker-compose.clustered-redis.yml` file.
3. Run the following command to create the patch:
    ```bash
    diff -Naru docker-compose.yml docker-compose.clustered-redis.yml > docker-compose.yml.patch
    ```
    Or the template command:
    ```bash
    diff -Naru [original file] [patched file] > [destination file].patch
    ```
4. Create a new directory in the `optional-modifications/patches` folder with the name of the patch. For example, `optional-modifications/patches/clustered-redis`.
5. Move the patched files (like `docker-compose.yml.patch` earlier) into the new directory.

## Official support

While Sentry employees aren't able to offer dedicated support for these patches, they can provide valuable information to help move things forward. Ultimately, we really encourage the community to take the wheel, maintaining and fostering these patches themselves. If you have questions, Sentry employees will be there to help guide you.

See the [support policy for self-hosted Sentry](https://develop.sentry.dev/self-hosted/support/) for more information.
