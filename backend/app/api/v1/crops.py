"""
HarvestLink Backend - Crop Information API.

Endpoints for crop data retrieval.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from app.core.security import get_current_user
from app.core.logging import get_logger
from app.services.crop_service import CropService
from app.models.schemas import CropListResponse, CropInfo

logger = get_logger(__name__)

router = APIRouter(prefix="/crops", tags=["Crop Information"])


@router.get("", response_model=CropListResponse)
async def list_crops(user: dict = Depends(get_current_user)):
    """Get all available crop information."""
    service = CropService()

    try:
        crops = await service.get_all_crops()
        return CropListResponse(
            crops=[CropInfo(**crop) if isinstance(crop, dict) else crop for crop in crops],
            count=len(crops),
        )
    except Exception as e:
        logger.error("crop_list_failed", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Crop information is currently unavailable.",
        )


@router.get("/{crop_name}")
async def get_crop(crop_name: str, user: dict = Depends(get_current_user)):
    """Get information for a specific crop."""
    service = CropService()

    try:
        crop = await service.get_crop_by_name(crop_name)
        if not crop:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Crop '{crop_name}' not found.",
            )
        return crop
    except HTTPException:
        raise
    except Exception as e:
        logger.error("crop_fetch_failed", crop=crop_name, error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to retrieve crop information.",
        )
