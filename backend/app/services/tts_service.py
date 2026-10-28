"""
HarvestLink Backend - ElevenLabs TTS Service.

Provides text-to-speech audio synthesis using ElevenLabs Multilingual v2 API.
Produces natural, expressive voice in Tamil and English for farmers.
"""

import httpx
from typing import Optional
from app.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)


class TTSService:
    """Async client for ElevenLabs Text-to-Speech synthesis."""

    BASE_URL = "https://api.elevenlabs.io/v1/text-to-speech"

    def __init__(self):
        settings = get_settings()
        self.api_key = settings.elevenlabs_api_key
        self.voice_id = settings.elevenlabs_voice_id or "EXAVITQu4vr4xnSDxMaL"
        self.model_id = settings.elevenlabs_model_id or "eleven_multilingual_v2"

    @property
    def is_configured(self) -> bool:
        return bool(self.api_key and self.api_key.strip())

    async def generate_speech(
        self,
        text: str,
        language: str = "ta",
        voice_id: Optional[str] = None,
    ) -> Optional[bytes]:
        """
        Synthesize plain text into MP3 audio bytes.

        Args:
            text: Text to synthesize (Tamil or English)
            language: Language code ('ta' or 'en')
            voice_id: Optional ElevenLabs voice ID override

        Returns:
            MP3 audio bytes, or None on failure.
        """
        if not self.is_configured:
            logger.warning("elevenlabs_not_configured")
            return None

        # Clean text: remove any remaining markdown formatting or extra whitespace
        cleaned_text = text.replace("*", "").replace("#", "").strip()
        if not cleaned_text:
            return None

        target_voice_id = voice_id or self.voice_id
        url = f"{self.BASE_URL}/{target_voice_id}"

        headers = {
            "xi-api-key": self.api_key,
            "Content-Type": "application/json",
            "Accept": "audio/mpeg",
        }

        payload = {
            "text": cleaned_text,
            "model_id": self.model_id,
            "voice_settings": {
                "stability": 0.5,
                "similarity_boost": 0.75,
                "style": 0.0,
                "use_speaker_boost": True,
            },
        }

        try:
            async with httpx.AsyncClient(timeout=25.0) as client:
                response = await client.post(
                    url,
                    json=payload,
                    headers=headers,
                )

                if response.status_code == 200:
                    return response.content
                else:
                    logger.error(
                        "elevenlabs_tts_api_error",
                        status_code=response.status_code,
                        response=response.text,
                    )
                    return None

        except Exception as e:
            logger.error("elevenlabs_tts_exception", error=str(e))
            return None
