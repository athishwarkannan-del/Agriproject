"""
HarvestLink Backend - Intent Classifier.

Uses Google Gemini to classify farmer queries into intents
and extract entities (dam names, locations, crop names, etc.).
"""

from google import genai
from app.config import get_settings
from app.core.logging import get_logger
from app.models.enums import Intent, Language
from typing import Optional
import json

logger = get_logger(__name__)

INTENT_CLASSIFICATION_PROMPT = """You are an intent classifier for HarvestLink, an agricultural assistant for Tamil Nadu farmers.

Classify the user's message into exactly ONE intent and extract relevant entities.

Available intents:
- dam_details: Questions about dam water levels, storage, inflow, outflow (e.g., "மேட்டூர் அணை நிலை என்ன?", "What is the water level of Mettur Dam?")
- weather_current: Questions about current weather conditions (e.g., "இன்று மழை பெய்யுமா?", "What's the weather today?")
- weather_forecast: Questions about future weather (e.g., "நாளை மழை வருமா?", "Will it rain tomorrow?")
- crop_information: Questions about specific crops, growing methods, seasons (e.g., "தக்காளி எப்படி வளர்ப்பது?", "How to grow tomatoes?")
- crop_recommendation: Asking which crop to plant based on conditions (e.g., "எந்த பயிர் போடலாம்?", "Which crop should I plant?")
- market_price: Questions about crop/produce prices (e.g., "தக்காளி விலை என்ன?", "What is the price of tomato?")
- disease_query: Questions about crop diseases or problems (e.g., "என் தக்காளி இலையில் புள்ளிகள் இருக்கு", "My tomato leaves have black spots")
- general_agriculture: General farming questions not fitting other categories
- greeting: Greetings like "வணக்கம்", "Hello", "Hi"
- unknown: Cannot determine intent

Respond ONLY with valid JSON:
{{
  "intent": "<intent_name>",
  "language": "<ta or en>",
  "entities": {{
    "dam_name": "<if applicable>",
    "location": "<if applicable>",
    "crop": "<if applicable>",
    "time_period": "<if applicable>"
  }},
  "requires_context": <true if this is a follow-up question referencing previous messages>
}}

Conversation context (if available):
{context}

User message:
{message}
"""


class IntentClassifier:
    """Classifies farmer queries into intents using Gemini AI or rule-based fallback."""

    def __init__(self):
        settings = get_settings()
        try:
            self.client = genai.Client(api_key=settings.gemini_api_key)
        except Exception:
            self.client = None
        self.model = "gemini-2.5-flash"

    def _rule_based_classify(self, message: str) -> dict:
        """Fallback rule-based intent classification."""
        msg_lower = message.lower()
        
        # Check Tamil language
        is_tamil = any('\u0b80' <= c <= '\u0bff' for c in message)
        lang = "ta" if is_tamil else "en"

        # Dam keywords
        dam_keywords = ["dam", "அணை", "mettur", "மேட்டூர்", "vaigai", "வைகை", "bhavanisagar", "பவானிசாகர்", "water level", "நீர்மட்டம்"]
        if any(kw in msg_lower for kw in dam_keywords):
            dam_name = ""
            if "mettur" in msg_lower or "மேட்டூர்" in msg_lower:
                dam_name = "mettur"
            elif "vaigai" in msg_lower or "வைகை" in msg_lower:
                dam_name = "vaigai"
            elif "bhavanisagar" in msg_lower or "பவானிசாகர்" in msg_lower:
                dam_name = "bhavanisagar"
            return {
                "intent": Intent.DAM_DETAILS,
                "language": lang,
                "entities": {"dam_name": dam_name} if dam_name else {},
                "requires_context": False,
            }

        # Weather keywords
        weather_keywords = ["weather", "rain", "temperature", "மழை", "வானிலை", "வெப்பநிலை"]
        if any(kw in msg_lower for kw in weather_keywords):
            is_forecast = "tomorrow" in msg_lower or "நாளை" in msg_lower or "forecast" in msg_lower
            return {
                "intent": Intent.WEATHER_FORECAST if is_forecast else Intent.WEATHER_CURRENT,
                "language": lang,
                "entities": {},
                "requires_context": False,
            }

        # Greeting keywords
        greeting_keywords = ["hello", "hi", "hey", "வணக்கம்", "நமஸ்தே"]
        if any(kw == msg_lower.strip() or kw in msg_lower.split() for kw in greeting_keywords):
            return {
                "intent": Intent.GREETING,
                "language": lang,
                "entities": {},
                "requires_context": False,
            }

        # Crop keywords
        crop_keywords = ["crop", "plant", "grow", "tomato", "rice", "paddy", "பயிர்", "தக்காளி", "நெல்"]
        if any(kw in msg_lower for kw in crop_keywords):
            return {
                "intent": Intent.CROP_INFORMATION,
                "language": lang,
                "entities": {},
                "requires_context": False,
            }

        return {
            "intent": Intent.GENERAL_AGRICULTURE,
            "language": lang,
            "entities": {},
            "requires_context": False,
        }

    async def classify(
        self,
        message: str,
        context: list[dict] = None,
    ) -> dict:
        """
        Classify a user message into an intent with extracted entities.
        """
        context_str = "No previous context."
        if context:
            context_lines = []
            for msg in context[-5:]:
                role = msg.get("role", "user")
                content = msg.get("content", "")
                context_lines.append(f"{role}: {content}")
            context_str = "\n".join(context_lines)

        try:
            if not self.client:
                raise ValueError("Gemini client not initialized")

            prompt = INTENT_CLASSIFICATION_PROMPT.format(
                context=context_str,
                message=message,
            )

            response = self.client.models.generate_content(
                model=self.model,
                contents=prompt,
                config=genai.types.GenerateContentConfig(
                    temperature=0.1,
                    max_output_tokens=300,
                ),
            )

            result_text = response.text.strip()

            # Clean markdown code fences if present
            if result_text.startswith("```"):
                result_text = result_text.split("\n", 1)[1] if "\n" in result_text else result_text[3:]
            if result_text.endswith("```"):
                result_text = result_text[:-3]
            result_text = result_text.strip()

            result = json.loads(result_text)

            intent_str = result.get("intent", "unknown")
            try:
                intent = Intent(intent_str)
            except ValueError:
                intent = Intent.UNKNOWN

            classification = {
                "intent": intent,
                "language": result.get("language", "ta"),
                "entities": result.get("entities", {}),
                "requires_context": result.get("requires_context", False),
            }

            logger.info(
                "intent_classified",
                intent=intent.value,
                language=classification["language"],
                entities=classification["entities"],
            )

            return classification

        except Exception as e:
            logger.warning("intent_classification_fallback", error=str(e))
            return self._rule_based_classify(message)
