"""
HarvestLink Backend - Dam Information API.

Endpoints for dam/reservoir data retrieval.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from app.core.security import get_current_user, get_optional_user
from app.core.logging import get_logger
from app.services.dam_service import DamDataProvider
from app.models.schemas import DamInfo, DamListResponse

logger = get_logger(__name__)

router = APIRouter(prefix="/dams", tags=["Dam Information"])


@router.get("")
async def list_dams(user: dict = Depends(get_optional_user)):
    """Get a list of all known dams formatted for the Flutter app."""
    provider = DamDataProvider()

    try:
        dams = await provider.get_all_dams()
        # Format specifically for the Flutter frontend
        flutter_dams = []
        for dam in dams:
            flutter_dams.append({
                "name": dam.get("dam_name"),
                "level": f"{dam.get('water_level_ft', 0):.1f} ft",
                "capacity": f"{dam.get('capacity_mcft', 0):.0f} mcft",
                "inflow": f"{dam.get('inflow_cusecs', 0):.0f} cusecs",
                "outflow": f"{dam.get('outflow_cusecs', 0):.0f} cusecs",
                "percentage": dam.get("current_storage_mcft", 0) / (dam.get("capacity_mcft", 1) or 1)
            })
            
        return {"data": flutter_dams}
    except Exception as e:
        logger.error("dam_list_failed", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Dam information is currently unavailable.",
        )


@router.get("/{dam_id}")
async def get_dam(dam_id: str, user: dict = Depends(get_current_user)):
    """Get detailed information for a specific dam."""
    provider = DamDataProvider()

    try:
        dam_data = await provider.get_dam_details(dam_id)
        return dam_data
    except Exception as e:
        logger.error("dam_fetch_failed", dam_id=dam_id, error=str(e))
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Dam '{dam_id}' not found or data unavailable.",
        )
