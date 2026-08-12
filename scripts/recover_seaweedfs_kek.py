#!/usr/bin/env python3
import argparse
import base64
import binascii
import re
import sys
from pathlib import Path

from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF

MAGIC = b"SWv2"
SALT_LENGTH = 32
NONCE_LENGTH = 12
LEGACY_SALT = b"seaweedfs-sse-s3-kek-wrapping-v1"


def recover_kek(stored_value: bytes, passphrase: bytes | None) -> str:
    value = stored_value.strip()
    if re.fullmatch(rb"[0-9a-fA-F]{64}", value):
        return value.decode().lower()

    passphrase = passphrase.strip() if passphrase else None
    if not passphrase:
        raise ValueError("the SeaweedFS KEK is wrapped but .mini_kek_passphrase is missing or empty")

    try:
        wrapped = base64.b64decode(value, validate=True)
    except (ValueError, binascii.Error) as error:
        raise ValueError("the filer KEK is neither 64-character hexadecimal nor valid base64") from error

    if wrapped.startswith(MAGIC):
        if len(wrapped) <= len(MAGIC) + SALT_LENGTH + NONCE_LENGTH:
            raise ValueError("the wrapped SeaweedFS v2 KEK is truncated")
        salt = wrapped[len(MAGIC) : len(MAGIC) + SALT_LENGTH]
        payload = wrapped[len(MAGIC) + SALT_LENGTH :]
    else:
        if len(wrapped) <= NONCE_LENGTH:
            raise ValueError("the wrapped SeaweedFS legacy KEK is truncated")
        salt = LEGACY_SALT
        payload = wrapped

    wrapping_key = HKDF(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        info=b"kek-wrapping",
    ).derive(passphrase)

    try:
        kek = AESGCM(wrapping_key).decrypt(payload[:NONCE_LENGTH], payload[NONCE_LENGTH:], None)
    except InvalidTag as error:
        raise ValueError("failed to decrypt the wrapped SeaweedFS KEK") from error

    if len(kek) != 32:
        raise ValueError(f"the recovered SeaweedFS KEK is {len(kek)} bytes; expected 32")
    return kek.hex()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("passphrase_file", type=Path)
    args = parser.parse_args()

    passphrase = args.passphrase_file.read_bytes() if args.passphrase_file.is_file() else None
    try:
        print(recover_kek(sys.stdin.buffer.read(), passphrase))
    except ValueError as error:
        parser.error(str(error))


if __name__ == "__main__":
    main()
