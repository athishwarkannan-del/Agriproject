"""
HarvestLink Backend - Weather Service.

Integrates with OpenWeatherMap API for real weather data.
"""

import httpx
from datetime import datetime, timezone
from typing import Optional
from app.config import get_settings
from app.core.logging import get_logger
from app.core.exceptions import ExternalAPIException
from app.models.schemas import WeatherInfo, WeatherForecastItem, WeatherForecastResponse

logger = get_logger(__name__)

OPENWEATHERMAP_CURRENT_URL = "https://api.openweathermap.org/data/2.5/weather"
OPENWEATHERMAP_FORECAST_URL = "https://api.openweathermap.org/data/2.5/forecast"
OPENWEATHERMAP_GEOCODING_URL = "http://api.openweathermap.org/geo/1.0/direct"


class WeatherService:
    """Retrieves real weather data from OpenWeatherMap API."""

    def __init__(self):
        self.settings = get_settings()
        self.api_key = self.settings.openweathermap_api_key

    async def _geocode_location(self, location_name: str) -> Optional[dict]:
        """Convert location name to coordinates using OpenWeatherMap geocoding."""
        if not self.api_key:
            return None

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(
                    OPENWEATHERMAP_GEOCODING_URL,
                    params={
                        "q": f"{location_name},IN",  # Restrict to India
                        "limit": 1,
                        "appid": self.api_key,
                    },
                )
                response.raise_for_status()
                data = response.json()
                if data:
                    return {"lat": data[0]["lat"], "lon": data[0]["lon"], "name": data[0].get("name", location_name)}
        except Exception as e:
            logger.error("geocoding_failed", location=location_name, error=str(e))
        return None

    async def get_current_weather(
        self,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None,
        location_name: Optional[str] = None,
    ) -> dict:
        """
        Get current weather data for a location.

        Uses coordinates if provided, otherwise geocodes the location name.
        """
        if not self.api_key:
            raise ExternalAPIException("weather")

        # Resolve coordinates
        if latitude is None or longitude is None:
            if location_name:
                geo = await self._geocode_location(location_name)
                if geo:
                    latitude, longitude = geo["lat"], geo["lon"]
                    location_name = geo["name"]
                else:
                    raise ExternalAPIException("weather")
            else:
                raise ExternalAPIException("weather")

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(
                    OPENWEATHERMAP_CURRENT_URL,
                    params={
                        "lat": latitude,
                        "lon": longitude,
                        "appid": self.api_key,
                        "units": "metric",
                    },
                )
                response.raise_for_status()
                data = response.json()

            weather_info = {
                "location": location_name or data.get("name", "Unknown"),
                "temperature_celsius": data["main"]["temp"],
                "feels_like_celsius": data["main"]["feels_like"],
                "humidity_percent": data["main"]["humidity"],
                "wind_speed_kmh": round(data["wind"]["speed"] * 3.6, 1),
                "wind_direction": self._wind_degree_to_direction(data["wind"].get("deg", 0)),
                "weather_condition": data["weather"][0]["main"] if data.get("weather") else None,
                "weather_description": data["weather"][0]["description"] if data.get("weather") else None,
                "rainfall_mm": data.get("rain", {}).get("1h", 0),
                "visibility_km": round(data.get("visibility", 0) / 1000, 1),
                "pressure_hpa": data["main"]["pressure"],
                "cloud_cover_percent": data.get("clouds", {}).get("all", 0),
                "sunrise": datetime.fromtimestamp(data["sys"]["sunrise"], tz=timezone.utc).isoformat() if data.get("sys", {}).get("sunrise") else None,
                "sunset": datetime.fromtimestamp(data["sys"]["sunset"], tz=timezone.utc).isoformat() if data.get("sys", {}).get("sunset") else None,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "source": "openweathermap",
            }

            logger.info("weather_fetched", location=weather_info["location"])
            return weather_info

        except httpx.HTTPStatusError as e:
            logger.error("weather_api_error", status=e.response.status_code, error=str(e))
            raise ExternalAPIException("weather")
        except Exception as e:
            logger.error("weather_fetch_failed", error=str(e))
            raise ExternalAPIException("weather")

    async def get_forecast(
        self,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None,
        location_name: Optional[str] = None,
        days: int = 5,
    ) -> dict:
        """Get weather forecast for a location."""
        if not self.api_key:
            raise ExternalAPIException("weather")

        # Resolve coordinates
        if latitude is None or longitude is None:
            if location_name:
                geo = await self._geocode_location(location_name)
                if geo:
                    latitude, longitude = geo["lat"], geo["lon"]
                    location_name = geo["name"]
                else:
                    raise ExternalAPIException("weather")
            else:
                raise ExternalAPIException("weather")

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(
                    OPENWEATHERMAP_FORECAST_URL,
                    params={
                        "lat": latitude,
                        "lon": longitude,
                        "appid": self.api_key,
                        "units": "metric",
                        "cnt": days * 8,  # 3-hour intervals
                    },
                )
                response.raise_for_status()
                data = response.json()

            # Aggregate by day
            daily_data = {}
            for item in data.get("list", []):
                date = item["dt_txt"].split(" ")[0]
                if date not in daily_data:
                    daily_data[date] = {
                        "temps": [],
                        "humidity": [],
                        "rainfall": 0,
                        "conditions": [],
                        "pop": [],
                    }
                daily_data[date]["temps"].append(item["main"]["temp"])
                daily_data[date]["humidity"].append(item["main"]["humidity"])
                daily_data[date]["rainfall"] += item.get("rain", {}).get("3h", 0)
                daily_data[date]["conditions"].append(item["weather"][0]["description"])
                daily_data[date]["pop"].append(item.get("pop", 0))

            forecast_items = []
            for date, day in list(daily_data.items())[:days]:
                forecast_items.append({
                    "date": date,
                    "temperature_min": round(min(day["temps"]), 1),
                    "temperature_max": round(max(day["temps"]), 1),
                    "humidity_percent": round(sum(day["humidity"]) / len(day["humidity"]), 1),
                    "rainfall_mm": round(day["rainfall"], 1),
                    "rainfall_probability": round(max(day["pop"]) * 100, 1),
                    "weather_condition": max(set(day["conditions"]), key=day["conditions"].count),
                    "weather_description": max(set(day["conditions"]), key=day["conditions"].count),
                })

            return {
                "location": location_name or data.get("city", {}).get("name", "Unknown"),
                "forecast": forecast_items,
                "source": "openweathermap",
            }

        except httpx.HTTPStatusError as e:
            logger.error("forecast_api_error", status=e.response.status_code)
            raise ExternalAPIException("weather")
        except Exception as e:
            logger.error("forecast_fetch_failed", error=str(e))
            raise ExternalAPIException("weather")

    @staticmethod
    def _wind_degree_to_direction(degree: float) -> str:
        """Convert wind degree to cardinal direction."""
        directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                       "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        index = round(degree / 22.5) % 16
        return directions[index]
