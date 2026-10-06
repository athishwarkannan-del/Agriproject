"""
HarvestLink Backend - Weather API.

Endpoints for real weather data retrieval.
"""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import Optional
from app.core.security import get_current_user, get_optional_user
from app.core.logging import get_logger
from app.services.weather_service import WeatherService

logger = get_logger(__name__)

router = APIRouter(prefix="/weather", tags=["Weather"])


@router.get("")
async def get_weather(
    lat: Optional[float] = Query(None, description="Latitude"),
    lon: Optional[float] = Query(None, description="Longitude"),
    location: Optional[str] = Query(None, description="Location name (e.g., Salem, Chennai)"),
    user: dict = Depends(get_optional_user),
):
    """Get current weather for a location."""
    service = WeatherService()

    try:
        weather = await service.get_current_weather(
            latitude=lat,
            longitude=lon,
            location_name=location,
        )
        return weather
    except Exception as e:
        logger.error("weather_endpoint_failed", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Weather information could not be retrieved. Please try again later.",
        )


@router.get("/forecast")
async def get_forecast(
    lat: Optional[float] = Query(None, description="Latitude"),
    lon: Optional[float] = Query(None, description="Longitude"),
    location: Optional[str] = Query(None, description="Location name"),
    days: int = Query(5, ge=1, le=7, description="Number of forecast days"),
    user: dict = Depends(get_optional_user),
):
    """Get weather forecast for a location."""
    service = WeatherService()

    try:
        forecast = await service.get_forecast(
            latitude=lat,
            longitude=lon,
            location_name=location,
            days=days,
        )
        return forecast
    except Exception as e:
        logger.error("forecast_endpoint_failed", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Weather forecast could not be retrieved.",
        )
