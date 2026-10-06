"""
HarvestLink Backend - Enumerations.

Shared enums used across the application.
"""

from enum import Enum


class Language(str, Enum):
    """Supported languages."""
    TAMIL = "ta"
    ENGLISH = "en"


class Intent(str, Enum):
    """AI-classified user intents."""
    DAM_DETAILS = "dam_details"
    WEATHER_CURRENT = "weather_current"
    WEATHER_FORECAST = "weather_forecast"
    CROP_INFORMATION = "crop_information"
    CROP_RECOMMENDATION = "crop_recommendation"
    MARKET_PRICE = "market_price"
    DISEASE_QUERY = "disease_query"
    GENERAL_AGRICULTURE = "general_agriculture"
    PROFILE_QUERY = "profile_query"
    GREETING = "greeting"
    UNKNOWN = "unknown"


class DiseaseStatus(str, Enum):
    """Disease prediction confidence status."""
    POSSIBLE = "possible"
    UNCERTAIN = "uncertain"
    UNIDENTIFIED = "unidentified"


class AnalysisStatus(str, Enum):
    """Image analysis processing status."""
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


class ConversationRole(str, Enum):
    """Message role in a conversation."""
    USER = "user"
    ASSISTANT = "assistant"
    SYSTEM = "system"
