"""
HarvestLink Backend Configuration.

Loads environment variables with validation using pydantic-settings.
"""

from pydantic_settings import BaseSettings
from pydantic import Field
from typing import Optional
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # ─── Supabase ─────────────────────────────────────
    supabase_url: str = Field(..., description="Supabase project URL")
    supabase_anon_key: str = Field(..., description="Supabase anonymous key")
    supabase_service_role_key: str = Field(..., description="Supabase service role key")

    # ─── AI / LLM ────────────────────────────────────
    gemini_api_key: str = Field(..., description="Google Gemini API key")

    # ─── Weather ──────────────────────────────────────
    openweathermap_api_key: str = Field(default="", description="OpenWeatherMap API key")

    # ─── Dam Data ─────────────────────────────────────
    dam_data_provider: str = Field(default="india_wris", description="Dam data provider name")
    dam_api_url: str = Field(default="", description="Dam data API URL")
    dam_api_key: str = Field(default="", description="Dam data API key")

    # ─── Disease Detection ML ─────────────────────────
    disease_model_path: str = Field(
        default="app/ml/models/disease_model.tflite",
        description="Path to the disease detection ML model"
    )
    disease_confidence_threshold: float = Field(
        default=0.60,
        description="Minimum confidence threshold for disease predictions"
    )

    # ─── Application ──────────────────────────────────
    app_env: str = Field(default="development")
    app_debug: bool = Field(default=True)
    app_host: str = Field(default="0.0.0.0")
    app_port: int = Field(default=8000)
    cors_origins: str = Field(default="*")

    # ─── Logging ──────────────────────────────────────
    log_level: str = Field(default="INFO")
    log_format: str = Field(default="json")

    @property
    def is_production(self) -> bool:
        return self.app_env == "production"

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",")]

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "case_sensitive": False,
    }


@lru_cache()
def get_settings() -> Settings:
    """Get cached application settings."""
    return Settings()
