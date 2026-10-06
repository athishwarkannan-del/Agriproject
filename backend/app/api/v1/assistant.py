"""
HarvestLink Backend - Assistant API.

The primary AI assistant query endpoint.
Farmer text/voice → AI orchestration → bilingual response.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from app.core.security import get_current_user, get_optional_user
from app.core.logging import get_logger
from app.models.schemas import AssistantQueryRequest, AssistantQueryResponse
from app.services.ai_orchestrator import AIOrchestrator

logger = get_logger(__name__)

router = APIRouter(prefix="/assistant", tags=["AI Assistant"])

# Lazy-initialized orchestrator
_orchestrator: AIOrchestrator | None = None


def get_orchestrator() -> AIOrchestrator:
    global _orchestrator
    if _orchestrator is None:
        _orchestrator = AIOrchestrator()
    return _orchestrator


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
