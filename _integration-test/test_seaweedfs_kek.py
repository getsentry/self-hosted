import base64
import importlib.util
from pathlib import Path

import pytest
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF

SCRIPT = Path(__file__).parents[1] / "scripts" / "recover_seaweedfs_kek.py"
spec = importlib.util.spec_from_file_location("recover_seaweedfs_kek", SCRIPT)
assert spec and spec.loader
recover_seaweedfs_kek = importlib.util.module_from_spec(spec)
spec.loader.exec_module(recover_seaweedfs_kek)


def wrap_kek(kek: bytes, passphrase: bytes, *, version: int) -> bytes:
    salt = b"s" * 32 if version == 2 else recover_seaweedfs_kek.LEGACY_SALT
    wrapping_key = HKDF(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        info=b"kek-wrapping",
    ).derive(passphrase)
    nonce = b"n" * 12
    payload = nonce + AESGCM(wrapping_key).encrypt(nonce, kek, None)
    if version == 2:
        payload = recover_seaweedfs_kek.MAGIC + salt + payload
    return base64.b64encode(payload)


def test_recovers_plaintext_hex_kek():
    assert recover_seaweedfs_kek.recover_kek(b"AB" * 32, None) == "ab" * 32


@pytest.mark.parametrize("version", [1, 2])
def test_recovers_wrapped_kek(version):
    kek = b"k" * 32
    passphrase = b"passphrase"

    assert recover_seaweedfs_kek.recover_kek(wrap_kek(kek, passphrase, version=version), passphrase) == kek.hex()


def test_rejects_wrapped_kek_without_passphrase():
    with pytest.raises(ValueError, match="passphrase is missing"):
        recover_seaweedfs_kek.recover_kek(wrap_kek(b"k" * 32, b"passphrase", version=2), None)


def test_rejects_wrong_passphrase():
    with pytest.raises(ValueError, match="failed to decrypt"):
        recover_seaweedfs_kek.recover_kek(wrap_kek(b"k" * 32, b"passphrase", version=2), b"wrong")
