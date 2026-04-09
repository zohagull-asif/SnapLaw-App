"""
Vault Encryption/Decryption for SnapLaw Privacy Vault.
Uses Fernet symmetric encryption with password-derived keys.
"""

from cryptography.fernet import Fernet, InvalidToken
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
import base64
import os
import logging

logger = logging.getLogger(__name__)


def generate_encryption_key(password: str, salt: bytes = None) -> tuple:
    """Generate encryption key from user password using PBKDF2."""
    if salt is None:
        salt = os.urandom(16)

    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=100000,
    )
    key = base64.urlsafe_b64encode(kdf.derive(password.encode()))
    return key, salt


def encrypt_file(file_bytes: bytes, password: str) -> dict:
    """Encrypt file bytes using user password."""
    try:
        key, salt = generate_encryption_key(password)
        f = Fernet(key)
        encrypted_data = f.encrypt(file_bytes)

        return {
            "encrypted_data": encrypted_data,
            "salt": base64.b64encode(salt).decode(),
            "success": True
        }
    except Exception as e:
        logger.error(f"Encryption failed: {e}")
        return {"success": False, "error": str(e)}


def decrypt_file(encrypted_data: bytes, password: str, salt_b64: str) -> dict:
    """Decrypt file bytes using user password."""
    try:
        salt = base64.b64decode(salt_b64)
        key, _ = generate_encryption_key(password, salt)
        f = Fernet(key)
        decrypted_data = f.decrypt(encrypted_data)

        return {"decrypted_data": decrypted_data, "success": True}
    except InvalidToken:
        return {"success": False, "error": "Wrong password or corrupted file"}
    except Exception as e:
        logger.error(f"Decryption failed: {e}")
        return {"success": False, "error": "Wrong password or corrupted file"}


def generate_share_token() -> str:
    """Generate secure random token for file sharing."""
    return base64.urlsafe_b64encode(os.urandom(32)).decode()
