"""
HarvestLink Backend - Pydantic Schemas.

Request and response models for all API endpoints.
"""

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from app.models.enums import Language, Intent, DiseaseStatus, AnalysisStatus


# ─── Auth Schemas ─────────────────────────────────────────

class RegisterRequest(BaseModel):
    email: Optional[str] = None
    phone: Optional[str] = None
    password: str = Field(..., min_length=6)
    name: str = Field(..., min_length=1, max_length=100)
    preferred_language: Language = Language.TAMIL


class LoginRequest(BaseModel):
    email: Optional[str] = None
    phone: Optional[str] = None
    password: str


class AuthResponse(BaseModel):
    access_token: str
    refresh_token: str
    user_id: str
    message: str


# ─── Farmer Profile Schemas ──────────────────────────────

class FarmerProfileCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    phone: Optional[str] = None
    preferred_language: Language = Language.TAMIL
    district: Optional[str] = None
    state: str = "Tamil Nadu"
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    farm_size_acres: Optional[float] = None
    soil_type: Optional[str] = None
    water_source: Optional[str] = None
    primary_crops: Optional[list[str]] = None


class FarmerProfileUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    preferred_language: Optional[Language] = None
    district: Optional[str] = None
    state: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    farm_size_acres: Optional[float] = None
    soil_type: Optional[str] = None
    water_source: Optional[str] = None
    primary_crops: Optional[list[str]] = None


class FarmerProfileResponse(BaseModel):
    id: str
    user_id: str
    name: str
    phone: Optional[str] = None
    preferred_language: Language
    district: Optional[str] = None
    state: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    farm_size_acres: Optional[float] = None
    soil_type: Optional[str] = None
    water_source: Optional[str] = None
    primary_crops: Optional[list[str]] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None


# ─── Assistant Schemas ───────────────────────────────────

class AssistantQueryRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    language: Language = Language.TAMIL
    conversation_id: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class AssistantQueryResponse(BaseModel):
    answer: str
    language: Language
    intent: Intent
    conversation_id: str
    source: Optional[str] = None
    data: Optional[dict] = None
    timestamp: str
    follow_up_prompt: Optional[str] = None


# ─── Dam Schemas ─────────────────────────────────────────

class DamInfo(BaseModel):
    dam_id: Optional[str] = None
    dam_name: str
    state: Optional[str] = None
    district: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    capacity_mcft: Optional[float] = None
    current_storage_mcft: Optional[float] = None
    storage_percentage: Optional[float] = None
    water_level_ft: Optional[float] = None
    inflow_cusecs: Optional[float] = None
    outflow_cusecs: Optional[float] = None
    last_updated: Optional[str] = None
    source: Optional[str] = None


class DamListResponse(BaseModel):
    dams: list[DamInfo]
    count: int
    source: Optional[str] = None
    last_updated: Optional[str] = None


# ─── Weather Schemas ─────────────────────────────────────

class WeatherInfo(BaseModel):
    location: str
    temperature_celsius: Optional[float] = None
    feels_like_celsius: Optional[float] = None
    humidity_percent: Optional[float] = None
    wind_speed_kmh: Optional[float] = None
    wind_direction: Optional[str] = None
    weather_condition: Optional[str] = None
    weather_description: Optional[str] = None
    rainfall_mm: Optional[float] = None
    visibility_km: Optional[float] = None
    pressure_hpa: Optional[float] = None
    cloud_cover_percent: Optional[float] = None
    sunrise: Optional[str] = None
    sunset: Optional[str] = None
    timestamp: Optional[str] = None
    source: str = "openweathermap"


class WeatherForecastItem(BaseModel):
    date: str
    temperature_min: Optional[float] = None
    temperature_max: Optional[float] = None
    humidity_percent: Optional[float] = None
    rainfall_mm: Optional[float] = None
    rainfall_probability: Optional[float] = None
    weather_condition: Optional[str] = None
    weather_description: Optional[str] = None


class WeatherForecastResponse(BaseModel):
    location: str
    forecast: list[WeatherForecastItem]
    source: str = "openweathermap"


# ─── Disease Detection Schemas ───────────────────────────

class DiseaseAnalysisResponse(BaseModel):
    analysis_id: str
    status: AnalysisStatus
    crop: Optional[str] = None
    disease: Optional[str] = None
    confidence: Optional[float] = None
    prediction_status: Optional[DiseaseStatus] = None
    symptoms: Optional[str] = None
    recommendations: Optional[list[str]] = None
    explanation: Optional[str] = None
    warning: Optional[str] = None
    language: Language = Language.TAMIL
    image_url: Optional[str] = None
    model_version: Optional[str] = None
    created_at: Optional[str] = None


# ─── Crop Schemas ────────────────────────────────────────

class CropInfo(BaseModel):
    id: Optional[str] = None
    name_en: str
    name_ta: str
    category: Optional[str] = None
    season: Optional[str] = None
    soil_type: Optional[str] = None
    water_requirement: Optional[str] = None
    growing_period_days: Optional[int] = None
    description_en: Optional[str] = None
    description_ta: Optional[str] = None


class CropListResponse(BaseModel):
    crops: list[CropInfo]
    count: int


# ─── Health Check ────────────────────────────────────────

class HealthResponse(BaseModel):
    status: str
    version: str
    environment: str
