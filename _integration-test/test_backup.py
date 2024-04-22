import os
import subprocess


def test_sentry_admin(setup_backup_restore_env_variables):
    sentry_admin_sh = os.path.join(os.getcwd(), "sentry-admin.sh")
    output = subprocess.run(
        [sentry_admin_sh, "--help"], check=True, capture_output=True, encoding="utf8"
    ).stdout
    assert "Usage: ./sentry-admin.sh" in output
    assert "SENTRY_DOCKER_IO_DIR" in output

    output = subprocess.run(
        [sentry_admin_sh, "permissions", "--help"],
        check=True,
        capture_output=True,
        encoding="utf8",
    ).stdout
    assert "Usage: ./sentry-admin.sh permissions" in output


def test_backup(setup_backup_restore_env_variables):
    # Docker was giving me permissioning issues when trying to create this file and write to it even after giving read + write access
    # to group and owner. Instead, try creating the empty file and then give everyone write access to the backup file
    file_path = os.path.join(os.getcwd(), "sentry", "backup.json")
    sentry_admin_sh = os.path.join(os.getcwd(), "sentry-admin.sh")
    open(file_path, "a", encoding="utf8").close()
    os.chmod(file_path, 0o666)
    assert os.path.getsize(file_path) == 0
    subprocess.run(
        [
            sentry_admin_sh,
            "export",
            "global",
            "/sentry-admin/backup.json",
            "--no-prompt",
        ],
        check=True,
    )
    assert os.path.getsize(file_path) > 0


def test_import(setup_backup_restore_env_variables):
    # Bring postgres down and recreate the docker volume
    subprocess.run(
        ["docker", "compose", "--ansi", "never", "stop", "postgres"], check=True
    )
    subprocess.run(
        ["docker", "compose", "--ansi", "never", "rm", "-f", "-v", "postgres"],
        check=True,
    )
    subprocess.run(["docker", "volume", "rm", "sentry-postgres"], check=True)
    subprocess.run(["docker", "volume", "create", "--name=sentry-postgres"], check=True)
    subprocess.run(
        ["docker", "compose", "--ansi", "never", "run", "web", "upgrade", "--noinput"],
        check=True,
    )
    subprocess.run(
        ["docker", "compose", "--ansi", "never", "up", "-d"],
        check=True,
        capture_output=True,
    )
    sentry_admin_sh = os.path.join(os.getcwd(), "sentry-admin.sh")
    subprocess.run(
        [
            sentry_admin_sh,
            "import",
            "global",
            "/sentry-admin/backup.json",
            "--no-prompt",
        ],
        check=True,
    )
