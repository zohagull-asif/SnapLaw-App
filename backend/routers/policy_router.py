"""
Policy Management API Router
Endpoints for uploading and managing company policies.
"""

from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Depends
from typing import List
import logging

from services.policy_service import process_policy_upload, load_user_policies_into_faiss

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/policies", tags=["Policies"])


def get_supabase():
    """Dependency to get Supabase client."""
    from main import supabase_client
    return supabase_client


@router.post("/upload")
async def upload_policy(
    file: UploadFile = File(...),
    user_id: str = Form(...),
    policy_name: str = Form(...),
    supabase=Depends(get_supabase),
):
    """
    Upload a company policy document.
    Extracts text, chunks it, embeds with LegalBERT, stores in Supabase + FAISS.
    """
    # Validate file type
    allowed_types = ["application/pdf", "text/plain"]
    if file.content_type not in allowed_types and not file.filename.endswith((".pdf", ".txt")):
        raise HTTPException(
            status_code=400,
            detail="Only PDF and TXT files are supported.",
        )

    # Read file content
    content = await file.read()
    if len(content) == 0:
        raise HTTPException(status_code=400, detail="Empty file uploaded.")

    if len(content) > 10 * 1024 * 1024:  # 10MB limit
        raise HTTPException(status_code=400, detail="File too large. Maximum 10MB.")

    try:
        result = await process_policy_upload(
            user_id=user_id,
            file_content=content,
            filename=file.filename,
            policy_name=policy_name,
            supabase_client=supabase,
        )
        return {"success": True, "data": result}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Policy upload failed: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to process policy: {str(e)}")


@router.get("/{user_id}")
async def get_user_policies(user_id: str, supabase=Depends(get_supabase)):
    """Get all policies uploaded by a user."""
    try:
        response = (
            supabase.table("company_policies")
            .select("id, policy_name, created_at")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .execute()
        )
        return {"success": True, "policies": response.data}
    except Exception as e:
        logger.error(f"Failed to fetch policies: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{policy_id}")
async def delete_policy(policy_id: str, user_id: str, supabase=Depends(get_supabase)):
    """Delete a policy and its chunks."""
    try:
        # Delete chunks first (cascade should handle this, but be explicit)
        supabase.table("policy_chunks").delete().eq("policy_id", policy_id).execute()
        supabase.table("company_policies").delete().eq("id", policy_id).execute()

        # Rebuild user's FAISS index
        await load_user_policies_into_faiss(user_id, supabase)

        return {"success": True, "message": "Policy deleted successfully"}
    except Exception as e:
        logger.error(f"Failed to delete policy: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/load-index/{user_id}")
async def load_user_index(user_id: str, supabase=Depends(get_supabase)):
    """Load a user's policy embeddings into FAISS (called on login or first analysis)."""
    try:
        await load_user_policies_into_faiss(user_id, supabase)
        return {"success": True, "message": "Index loaded"}
    except Exception as e:
        logger.error(f"Failed to load index: {e}")
        raise HTTPException(status_code=500, detail=str(e))
