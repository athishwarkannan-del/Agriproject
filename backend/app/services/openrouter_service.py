"""
HarvestLink Backend - OpenRouter Service.

Centralized client for interacting with LLM models via OpenRouter API.
Provides OpenAI-compatible chat completion routing with timeout and error handling.
"""

import httpx
from typing import Optional, List, Dict
from app.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)


class OpenRouterService:
    """Async client for OpenRouter LLM completions."""

    BASE_URL = "https://openrouter.ai/api/v1/chat/completions"

    def __init__(self):
        settings = get_settings()
        self.api_key = settings.openrouter_api_key
        self.model = settings.openrouter_model or "google/gemini-3.5-flash-lite"

    @property
    def is_configured(self) -> bool:
        return bool(self.api_key and self.api_key.strip())

    async def chat_completion(
        self,
        messages: List[Dict[str, str]],
        temperature: float = 0.3,
        max_tokens: int = 300,
        model: Optional[str] = None,
    ) -> Optional[str]:
        """
        Send a chat completion request to OpenRouter.

        Args:
            messages: List of message dicts with 'role' and 'content'
            temperature: Sampling temperature
            max_tokens: Maximum tokens in response
            model: Optional model override

        Returns:
            The text response from the model, or None on failure.
        """
        if not self.is_configured:
            logger.warning("openrouter_not_configured")
            return None

        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://harvestlink.app",
            "X-Title": "HarvestLink",
        }

        payload = {
            "model": model or self.model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
        }

        try:
            async with httpx.AsyncClient(timeout=20.0) as client:
                response = await client.post(
                    self.BASE_URL,
                    json=payload,
                    headers=headers,
                )

                if response.status_code == 200:
                    data = response.json()
                    choices = data.get("choices", [])
                    if choices:
                        return choices[0]["message"]["content"].strip()
                    return None
                else:
                    logger.error(
                        "openrouter_api_error",
                        status_code=response.status_code,
                        response=response.text,
                    )
                    return None

        except Exception as e:
            logger.error("openrouter_request_exception", error=str(e))
            return None
