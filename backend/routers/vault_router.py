"""
Privacy Vault Router — Encrypted file storage endpoints.
Uses Supabase user_id from Flutter client (no separate auth).
"""

from fastapi import APIRouter, UploadFile, File, HTTPException, Form, Depends
from fastapi.responses import Response
from services.vault_crypto import encrypt_file, decrypt_file, generate_share_token
from services.vault_storage import VaultFile, get_vault_db, CATEGORIES
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import uuid
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

MAX_FILE_SIZE = 20 * 1024 * 1024  # 20MB


@router.post("/api/vault/upload")
async def upload_file(
    file: UploadFile = File(...),
    user_id: str = Form(...),
    password: str = Form(...),
    category: str = Form("General"),
    description: str = Form(""),
    db: Session = Depends(get_vault_db),
):
    """Upload and encrypt a file to the vault."""
    if not user_id:
        raise HTTPException(status_code=400, detail="User ID required")

    file_bytes = await file.read()

    if len(file_bytes) > MAX_FILE_SIZE:
        raise HTTPException(status_code=400, detail="File too large. Max 20MB.")

    if len(password) < 4:
        raise HTTPException(status_code=400, detail="Password must be at least 4 characters")

    # Encrypt the file
    encrypted = encrypt_file(file_bytes, password)
    if not encrypted["success"]:
        raise HTTPException(status_code=500, detail="Encryption failed")

    vault_file = VaultFile(
        id=str(uuid.uuid4()),
        user_id=user_id,
        filename=f"{uuid.uuid4()}_{file.filename}",
        original_filename=file.filename or "document",
        file_type=file.content_type or "application/octet-stream",
        file_size=len(file_bytes),
        category=category if category in CATEGORIES else "General",
        description=description,
        encrypted_data=encrypted["encrypted_data"],
        encryption_salt=encrypted["salt"],
    )

    db.add(vault_file)
    db.commit()

    logger.info(f"Vault file uploaded: {file.filename} by user {user_id[:8]}...")

    return {
        "success": True,
        "file_id": vault_file.id,
        "filename": vault_file.original_filename,
        "category": vault_file.category,
        "size": vault_file.file_size,
        "uploaded_at": vault_file.uploaded_at.isoformat(),
    }


@router.get("/api/vault/files/{user_id}")
async def list_files(
    user_id: str,
    category: str = None,
    db: Session = Depends(get_vault_db),
):
    """List all vault files for a user (without encrypted data)."""
    query = db.query(VaultFile).filter(
        VaultFile.user_id == user_id,
        VaultFile.is_deleted == False,
    )

    if category and category != "All":
        query = query.filter(VaultFile.category == category)

    files = query.order_by(VaultFile.uploaded_at.desc()).all()

    return {
        "files": [
            {
                "id": f.id,
                "filename": f.original_filename,
                "category": f.category,
                "description": f.description,
                "file_type": f.file_type,
                "size": f.file_size,
                "uploaded_at": f.uploaded_at.isoformat(),
                "has_share_link": f.share_token is not None,
            }
            for f in files
        ],
        "total": len(files),
    }


@router.post("/api/vault/download/{file_id}")
async def download_file(
    file_id: str,
    user_id: str = Form(...),
    password: str = Form(...),
    db: Session = Depends(get_vault_db),
):
    """Decrypt and download a vault file."""
    vault_file = db.query(VaultFile).filter(
        VaultFile.id == file_id,
        VaultFile.user_id == user_id,
        VaultFile.is_deleted == False,
    ).first()

    if not vault_file:
        raise HTTPException(status_code=404, detail="File not found")

    result = decrypt_file(
        vault_file.encrypted_data,
        password,
        vault_file.encryption_salt,
    )

    if not result["success"]:
        raise HTTPException(
            status_code=401,
            detail="Wrong password. Cannot decrypt file.",
        )

    return Response(
        content=result["decrypted_data"],
        media_type=vault_file.file_type,
        headers={
            "Content-Disposition": f'attachment; filename="{vault_file.original_filename}"'
        },
    )


@router.post("/api/vault/share/{file_id}")
async def create_share_link(
    file_id: str,
    user_id: str = Form(...),
    hours: int = Form(24),
    db: Session = Depends(get_vault_db),
):
    """Create a temporary share link for a vault file."""
    vault_file = db.query(VaultFile).filter(
        VaultFile.id == file_id,
        VaultFile.user_id == user_id,
    ).first()

    if not vault_file:
        raise HTTPException(status_code=404, detail="File not found")

    token = generate_share_token()
    vault_file.share_token = token
    vault_file.share_expires_at = datetime.utcnow() + timedelta(hours=hours)
    db.commit()

    return {
        "success": True,
        "share_token": token,
        "expires_in_hours": hours,
        "filename": vault_file.original_filename,
    }


@router.delete("/api/vault/delete/{file_id}")
async def delete_file(
    file_id: str,
    user_id: str,
    db: Session = Depends(get_vault_db),
):
    """Soft-delete a vault file."""
    vault_file = db.query(VaultFile).filter(
        VaultFile.id == file_id,
        VaultFile.user_id == user_id,
    ).first()

    if not vault_file:
        raise HTTPException(status_code=404, detail="File not found")

    vault_file.is_deleted = True
    db.commit()

    logger.info(f"Vault file deleted: {vault_file.original_filename}")
    return {"success": True, "message": "File deleted from vault"}


@router.get("/api/vault/categories")
async def get_categories():
    """Return available categories."""
    return {"categories": CATEGORIES}
