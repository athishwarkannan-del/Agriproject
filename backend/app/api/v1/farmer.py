"""
HarvestLink Backend - Farmer Profile API.

Manage farmer profile data.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from app.core.security import get_current_user
from app.core.database import get_supabase_client
from app.core.logging import get_logger
from app.models.schemas import FarmerProfileCreate, FarmerProfileUpdate, FarmerProfileResponse

logger = get_logger(__name__)

router = APIRouter(prefix="/farmer", tags=["Farmer Profile"])


@router.get("/profile", response_model=FarmerProfileResponse)
async def get_profile(user: dict = Depends(get_current_user)):
    """Get the current farmer's profile."""
    db = get_supabase_client()

    try:
        result = (
            db.table("farmer_profiles")
            .select("*")
            .eq("user_id", user["user_id"])
            .execute()
        )

        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Farmer profile not found. Please complete your registration.",
            )

        return FarmerProfileResponse(**result.data[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error("profile_fetch_failed", user_id=user["user_id"], error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to retrieve profile.",
        )


@router.put("/profile", response_model=FarmerProfileResponse)
async def update_profile(
    request: FarmerProfileUpdate,
    user: dict = Depends(get_current_user),
):
    """Update the farmer's profile. Only provided fields are updated."""
    db = get_supabase_client()

    try:
        update_data = request.model_dump(exclude_none=True)
        if not update_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No fields to update.",
            )

        # Convert language enum to value if present
        if "preferred_language" in update_data:
            update_data["preferred_language"] = update_data["preferred_language"].value

        result = (
            db.table("farmer_profiles")
            .update(update_data)
            .eq("user_id", user["user_id"])
            .execute()
        )

        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Profile not found.",
            )

        logger.info("profile_updated", user_id=user["user_id"])
        return FarmerProfileResponse(**result.data[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error("profile_update_failed", user_id=user["user_id"], error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to update profile.",
        )


@router.post("/profile", response_model=FarmerProfileResponse, status_code=status.HTTP_201_CREATED)
async def create_profile(
    request: FarmerProfileCreate,
    user: dict = Depends(get_current_user),
):
    """Create a new farmer profile (if one doesn't exist)."""
    db = get_supabase_client()

    try:
        # Check if profile already exists
        existing = (
            db.table("farmer_profiles")
            .select("id")
            .eq("user_id", user["user_id"])
            .execute()
        )

        if existing.data:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Profile already exists. Use PUT to update.",
            )

        profile_data = request.model_dump()
        profile_data["user_id"] = user["user_id"]
        profile_data["preferred_language"] = profile_data["preferred_language"].value

        result = db.table("farmer_profiles").insert(profile_data).execute()

        logger.info("profile_created", user_id=user["user_id"])
        return FarmerProfileResponse(**result.data[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error("profile_creation_failed", user_id=user["user_id"], error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to create profile.",
        )
