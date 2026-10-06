"""
HarvestLink Backend - AI Orchestrator.

The central intelligence layer that:
1. Receives the farmer's message
2. Classifies intent
3. Routes to the correct backend tool
4. Retrieves real data
5. Generates a farmer-friendly response

Never sends every question directly to an LLM.
"""

from datetime import datetime, timezone
from typing import Optional
from app.core.logging import get_logger
from app.models.enums import Intent, Language, ConversationRole
from app.services.intent_classifier import IntentClassifier
from app.services.response_generator import ResponseGenerator
from app.services.conversation_service import ConversationService
from app.services.dam_service import DamDataProvider
from app.services.weather_service import WeatherService
from app.services.crop_service import CropService

logger = get_logger(__name__)


class AIOrchestrator:
    """
    Orchestrates the full query pipeline:
    Message → Intent → Tool → Data → Response
    """

    def __init__(self):
        self.intent_classifier = IntentClassifier()
        self.response_generator = ResponseGenerator()
        self.conversation_service = ConversationService()
        self.dam_provider = DamDataProvider()
        self.weather_service = WeatherService()
        self.crop_service = CropService()

    async def process_query(
        self,
        user_id: str,
        message: str,
        language: str = "ta",
        conversation_id: Optional[str] = None,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None,
    ) -> dict:
        """
        Process a farmer's query through the full AI pipeline.

        Args:
            user_id: Authenticated user ID
            message: The farmer's text message (Tamil or English)
            language: Preferred response language
            conversation_id: Existing conversation ID for context
            latitude: User's latitude for location-based services
            longitude: User's longitude for location-based services

        Returns:
            Complete response dict with answer, intent, source, etc.
        """
        # 1. Get or create conversation
        conversation_id = self.conversation_service.get_or_create_conversation(
            user_id, conversation_id
        )

        # 2. Get conversation context for follow-up understanding
        context = self.conversation_service.get_conversation_context(conversation_id)

        # 3. Save user message
        self.conversation_service.add_message(
            conversation_id, ConversationRole.USER, message
        )

        # 4. Classify intent
        classification = await self.intent_classifier.classify(message, context)
        intent = classification["intent"]
        entities = classification["entities"]
        detected_language = classification["language"]

        # Use detected language if farmer hasn't set preference explicitly
        response_language = language or detected_language

        logger.info(
            "query_processing",
            user_id=user_id,
            intent=intent.value,
            entities=entities,
        )

        # 5. Route to appropriate tool and get data
        tool_data = await self._route_to_tool(
            intent=intent,
            entities=entities,
            language=response_language,
            latitude=latitude,
            longitude=longitude,
        )

        # 6. Generate response using real data
        response_result = await self.response_generator.generate(
            user_message=message,
            intent=intent.value,
            entities=entities,
            tool_data=tool_data,
            language=response_language,
            conversation_history=context,
        )

        # 7. Save assistant response
        self.conversation_service.add_message(
            conversation_id,
            ConversationRole.ASSISTANT,
            response_result["answer"],
            metadata={"intent": intent.value, "entities": entities},
        )

        # 8. Build final response
        return {
            "answer": response_result["answer"],
            "language": response_language,
            "intent": intent.value,
            "conversation_id": conversation_id,
            "source": response_result.get("source"),
            "data": tool_data if isinstance(tool_data, dict) else None,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "follow_up_prompt": response_result.get("follow_up_prompt"),
        }

    async def _route_to_tool(
        self,
        intent: Intent,
        entities: dict,
        language: str,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None,
    ) -> Optional[dict | str]:
        """
        Route the classified intent to the appropriate backend tool.

        Returns the real data retrieved from the tool, or None.
        """
        try:
            if intent == Intent.DAM_DETAILS:
                return await self._handle_dam_query(entities)

            elif intent in (Intent.WEATHER_CURRENT, Intent.WEATHER_FORECAST):
                return await self._handle_weather_query(
                    intent, entities, latitude, longitude
                )

            elif intent == Intent.CROP_INFORMATION:
                return await self._handle_crop_query(entities)

            elif intent == Intent.CROP_RECOMMENDATION:
                return await self._handle_crop_recommendation(
                    entities, latitude, longitude
                )

            elif intent == Intent.DISEASE_QUERY:
                # For disease queries via text, suggest uploading a photo
                return {
                    "action": "suggest_photo_upload",
                    "message_en": "Please upload a photo of the affected plant leaf for accurate disease detection.",
                    "message_ta": "துல்லியமான நோய் கண்டறிதலுக்கு பாதிக்கப்பட்ட இலையின் புகைப்படத்தை பதிவேற்றவும்.",
                }

            elif intent == Intent.GREETING:
                return {"type": "greeting"}

            elif intent == Intent.GENERAL_AGRICULTURE:
                return None  # Let the LLM handle general questions directly

            elif intent == Intent.MARKET_PRICE:
                return {
                    "note": "Market price integration pending — will be connected to real market data source.",
                    "status": "not_available_yet",
                }

            else:
                return None

        except Exception as e:
            logger.error("tool_routing_failed", intent=intent.value, error=str(e))
            return {"error": str(e), "status": "tool_failed"}

    async def _handle_dam_query(self, entities: dict) -> dict:
        """Handle dam information queries."""
        dam_name = entities.get("dam_name", "")
        dam_key = self.dam_provider.resolve_dam_name(dam_name)

        if dam_key:
            return await self.dam_provider.get_dam_details(dam_key)
        else:
            # If no specific dam, return list of available dams
            dams = await self.dam_provider.get_all_dams()
            return {
                "type": "dam_list",
                "dams": dams,
                "note": "No specific dam identified. Showing available dams.",
            }

    async def _handle_weather_query(
        self,
        intent: Intent,
        entities: dict,
        latitude: Optional[float],
        longitude: Optional[float],
    ) -> dict:
        """Handle weather queries."""
        location = entities.get("location")

        if intent == Intent.WEATHER_FORECAST:
            return await self.weather_service.get_forecast(
                latitude=latitude,
                longitude=longitude,
                location_name=location,
            )
        else:
            return await self.weather_service.get_current_weather(
                latitude=latitude,
                longitude=longitude,
                location_name=location,
            )

    async def _handle_crop_query(self, entities: dict) -> Optional[dict]:
        """Handle crop information queries."""
        crop_name = entities.get("crop", "")
        if crop_name:
            crop = await self.crop_service.get_crop_by_name(crop_name)
            if crop:
                return crop
        # Return all crops if no specific crop mentioned
        crops = await self.crop_service.get_all_crops()
        return {"type": "crop_list", "crops": crops}

    async def _handle_crop_recommendation(
        self,
        entities: dict,
        latitude: Optional[float],
        longitude: Optional[float],
    ) -> dict:
        """
        Handle crop recommendation queries.

        Gathers context (location, weather, etc.) to inform the AI's recommendation.
        """
        recommendation_context = {
            "type": "crop_recommendation",
            "location": entities.get("location"),
            "latitude": latitude,
            "longitude": longitude,
            "season": entities.get("time_period"),
        }

        # Try to get weather data for the recommendation
        try:
            location = entities.get("location")
            if latitude and longitude:
                weather = await self.weather_service.get_current_weather(
                    latitude=latitude, longitude=longitude
                )
                recommendation_context["weather"] = weather
            elif location:
                weather = await self.weather_service.get_current_weather(
                    location_name=location
                )
                recommendation_context["weather"] = weather
        except Exception:
            pass  # Weather data is optional for recommendations

        return recommendation_context
