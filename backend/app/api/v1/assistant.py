"""
HarvestLink Backend - Assistant API.

The primary AI assistant query endpoint.
Farmer text/voice → AI orchestration → bilingual response.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Response
from pydantic import BaseModel
from typing import Optional
from app.core.security import get_current_user, get_optional_user
from app.core.logging import get_logger
from app.models.schemas import AssistantQueryRequest, AssistantQueryResponse
from app.services.ai_orchestrator import AIOrchestrator
from app.services.tts_service import TTSService

logger = get_logger(__name__)

router = APIRouter(prefix="/assistant", tags=["AI Assistant"])

# Lazy-initialized services
_orchestrator: AIOrchestrator | None = None
_tts_service: TTSService | None = None


def get_orchestrator() -> AIOrchestrator:
    global _orchestrator
    if _orchestrator is None:
        _orchestrator = AIOrchestrator()
    return _orchestrator


def get_tts_service() -> TTSService:
    global _tts_service
    if _tts_service is None:
        _tts_service = TTSService()
    return _tts_service


class TTSRequest(BaseModel):
    text: str
    language: str = "ta"
    voice_id: Optional[str] = None


@router.post("/tts")
async def synthesize_speech(request: TTSRequest):
    """
    Synthesize text into natural voice audio using ElevenLabs Multilingual v2.
    Returns audio/mpeg.
    """
    tts = get_tts_service()
    if not tts.is_configured:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="ElevenLabs TTS service is not configured.",
        )

    audio_bytes = await tts.generate_speech(
        text=request.text,
        language=request.language,
        voice_id=request.voice_id,
    )

    if not audio_bytes:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Failed to synthesize speech audio from ElevenLabs.",
        )

    return Response(
        content=audio_bytes,
        media_type="audio/mpeg",
        headers={
            "Content-Disposition": "inline; filename=speech.mp3",
            "Cache-Control": "public, max-age=86400",
        },
    )


@router.post("/query", response_model=AssistantQueryResponse)
async def query_assistant(
    request: AssistantQueryRequest,
    user: dict = Depends(get_optional_user),
):
    """
    Process a farmer's query through the AI assistant pipeline.

    The orchestrator:
    1. Classifies intent (dam, weather, crop, disease, etc.)
    2. Routes to the appropriate backend tool
    3. Retrieves real data
    4. Generates a farmer-friendly response in Tamil or English
    """
    orchestrator = get_orchestrator()

    try:
        # Provide a mock user_id for dev mode bypassing auth
        user_id = user["user_id"] if user else "test_farmer_dev_mode"
        
        result = await orchestrator.process_query(
            user_id=user_id,
            message=request.message,
            language=request.language.value,
            conversation_id=request.conversation_id,
            latitude=request.latitude,
            longitude=request.longitude,
        )

        return AssistantQueryResponse(**result)

    except Exception as e:
        logger.error(
            "assistant_query_failed",
            user_id=user["user_id"] if user else "unknown",
            error=str(e),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to process your request. Please try again.",
        )
