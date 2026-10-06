"""
HarvestLink Backend - Core Exceptions.

Structured exception handling for farmer-friendly error messages
in both Tamil and English.
"""

from fastapi import HTTPException, status
from typing import Optional


# ─── Bilingual Error Messages ─────────────────────────────

ERROR_MESSAGES = {
    "network_error": {
        "en": "Unable to connect to the server. Please check your internet connection and try again.",
        "ta": "சேவையகத்துடன் இணைக்க முடியவில்லை. உங்கள் இணைய இணைப்பை சரிபார்த்து மீண்டும் முயற்சிக்கவும்.",
    },
    "api_timeout": {
        "en": "The request took too long. Please try again.",
        "ta": "கோரிக்கை அதிக நேரம் எடுத்தது. மீண்டும் முயற்சிக்கவும்.",
    },
    "service_unavailable": {
        "en": "This service is temporarily unavailable. Please try again later.",
        "ta": "இந்த சேவை தற்காலிகமாக கிடைக்கவில்லை. பின்னர் மீண்டும் முயற்சிக்கவும்.",
    },
    "invalid_image": {
        "en": "The uploaded image is not valid. Please upload a clear photo of the affected crop leaf.",
        "ta": "பதிவேற்றப்பட்ட படம் செல்லுபடியாகவில்லை. பாதிக்கப்பட்ட பயிர் இலையின் தெளிவான புகைப்படத்தை பதிவேற்றவும்.",
    },
    "image_too_large": {
        "en": "The image is too large. Please upload an image smaller than 10 MB.",
        "ta": "படம் மிகவும் பெரியது. 10 MB-க்கும் குறைவான படத்தை பதிவேற்றவும்.",
    },
    "speech_recognition_failed": {
        "en": "Sorry, I couldn't understand the audio. Please try again.",
        "ta": "மன்னிக்கவும், உங்கள் குரலை சரியாக புரிந்துகொள்ள முடியவில்லை. மீண்டும் முயற்சிக்கவும்.",
    },
    "data_not_available": {
        "en": "Current data could not be retrieved. Please try again later.",
        "ta": "தற்போதைய தகவலை பெற முடியவில்லை. பின்னர் மீண்டும் முயற்சிக்கவும்.",
    },
    "authentication_failed": {
        "en": "Login failed. Please check your credentials and try again.",
        "ta": "உள்நுழைவு தோல்வியடைந்தது. உங்கள் தகவல்களை சரிபார்த்து மீண்டும் முயற்சிக்கவும்.",
    },
    "unauthorized": {
        "en": "You are not authorized. Please log in.",
        "ta": "அங்கீகாரம் இல்லை. உள்நுழையவும்.",
    },
    "disease_detection_failed": {
        "en": "Unable to analyze the image. Please try with a clearer photo.",
        "ta": "படத்தை பகுப்பாய்வு செய்ய முடியவில்லை. தெளிவான புகைப்படத்துடன் மீண்டும் முயற்சிக்கவும்.",
    },
    "dam_data_unavailable": {
        "en": "Dam information is currently unavailable. Please try again later.",
        "ta": "அணை தகவல் தற்போது கிடைக்கவில்லை. பின்னர் மீண்டும் முயற்சிக்கவும்.",
    },
    "weather_data_unavailable": {
        "en": "Weather information could not be retrieved. Please try again later.",
        "ta": "வானிலை தகவலை பெற முடியவில்லை. பின்னர் மீண்டும் முயற்சிக்கவும்.",
    },
    "profile_not_found": {
        "en": "Farmer profile not found. Please complete your registration.",
        "ta": "விவசாயி சுயவிவரம் கிடைக்கவில்லை. உங்கள் பதிவை முடிக்கவும்.",
    },
    "internal_error": {
        "en": "Something went wrong. Please try again.",
        "ta": "ஏதோ தவறு ஏற்பட்டது. மீண்டும் முயற்சிக்கவும்.",
    },
}


def get_error_message(error_key: str, language: str = "en") -> str:
    """Get a farmer-friendly error message in the specified language."""
    messages = ERROR_MESSAGES.get(error_key, ERROR_MESSAGES["internal_error"])
    return messages.get(language, messages["en"])


class HarvestLinkException(Exception):
    """Base exception for HarvestLink application."""

    def __init__(
        self,
        error_key: str = "internal_error",
        language: str = "en",
        detail: Optional[str] = None,
        log_message: Optional[str] = None,
    ):
        self.error_key = error_key
        self.language = language
        self.user_message = detail or get_error_message(error_key, language)
        self.log_message = log_message or self.user_message
        super().__init__(self.log_message)


class DataUnavailableException(HarvestLinkException):
    """Raised when external data source is unavailable."""

    def __init__(self, source: str, language: str = "en"):
        super().__init__(
            error_key="data_not_available",
            language=language,
            log_message=f"Data unavailable from source: {source}",
        )


class DiseaseDetectionException(HarvestLinkException):
    """Raised when disease detection fails."""

    def __init__(self, reason: str, language: str = "en"):
        super().__init__(
            error_key="disease_detection_failed",
            language=language,
            log_message=f"Disease detection failed: {reason}",
        )


class ImageValidationException(HarvestLinkException):
    """Raised when uploaded image fails validation."""

    def __init__(self, error_key: str = "invalid_image", language: str = "en"):
        super().__init__(error_key=error_key, language=language)


class ExternalAPIException(HarvestLinkException):
    """Raised when an external API call fails."""

    def __init__(self, service: str, language: str = "en"):
        super().__init__(
            error_key="service_unavailable",
            language=language,
            log_message=f"External API failure: {service}",
        )
