"""
HarvestLink Backend - Response Generator.

Uses Google Gemini to generate farmer-friendly responses
in Tamil or English, using real data from backend tools.
"""

from google import genai
from app.config import get_settings
from app.core.logging import get_logger
from app.models.enums import Language

logger = get_logger(__name__)

RESPONSE_GENERATION_PROMPT = """You are HarvestLink, a friendly AI agricultural assistant for farmers in Tamil Nadu, India.

RULES:
1. Respond in {language_name} ({language_code}).
2. Use simple, non-technical language that a farmer can easily understand.
3. Be concise but helpful.
4. If real data is provided, use it accurately. NEVER invent data values.
5. If data could not be retrieved, clearly say so.
6. If you need more information from the farmer (location, soil, crop type, etc.), ask a follow-up question.
7. For disease-related queries, suggest uploading a photo for analysis.
8. For pesticide/fertilizer recommendations, advise consulting a local agricultural expert.
9. Mention data source and timestamp when presenting live data.
10. Use appropriate agricultural terminology in Tamil when responding in Tamil.
11. CRITICAL: Do NOT use any Markdown formatting (like **bold** or # headings) because your response will be read aloud by a Voice Assistant. Use plain text only.

CONTEXT:
Intent: {intent}
Entities: {entities}

DATA FROM TOOL (if any):
{tool_data}

CONVERSATION HISTORY:
{conversation_history}

USER MESSAGE:
{user_message}

Generate a helpful response for the farmer:"""


class ResponseGenerator:
    """Generates farmer-friendly responses using Gemini AI."""

    def __init__(self):
        settings = get_settings()
        self.client = genai.Client(api_key=settings.gemini_api_key)
        self.model = "gemini-1.5-flash"

    async def generate(
        self,
        user_message: str,
        intent: str,
        entities: dict,
        tool_data: dict | str | None,
        language: str,
        conversation_history: list[dict] = None,
    ) -> dict:
        """
        Generate a response for the farmer using real data.

        Args:
            user_message: Original farmer query
            intent: Classified intent
            entities: Extracted entities
            tool_data: Data retrieved from backend tool (or None)
            language: Response language ('ta' or 'en')
            conversation_history: Previous messages for context

        Returns:
            dict with 'answer', 'follow_up_prompt', and 'source'
        """
        language_name = "Tamil" if language == "ta" else "English"

        # Format conversation history
        history_str = "No previous conversation."
        if conversation_history:
            history_lines = []
            for msg in conversation_history[-5:]:
                role = msg.get("role", "user")
                content = msg.get("content", "")
                history_lines.append(f"{role}: {content}")
            history_str = "\n".join(history_lines)

        # Format tool data
        tool_data_str = "No data retrieved."
        source = None
        if tool_data:
            if isinstance(tool_data, dict):
                source = tool_data.get("source")
                tool_data_str = str(tool_data)
            else:
                tool_data_str = str(tool_data)

        prompt = RESPONSE_GENERATION_PROMPT.format(
            language_name=language_name,
            language_code=language,
            intent=intent,
            entities=str(entities),
            tool_data=tool_data_str,
            conversation_history=history_str,
            user_message=user_message,
        )

        try:
            response = self.client.models.generate_content(
                model=self.model,
                contents=prompt,
                config=genai.types.GenerateContentConfig(
                    temperature=0.7,
                    max_output_tokens=1000,
                ),
            )

            answer = response.text.strip()

            logger.info(
                "response_generated",
                intent=intent,
                language=language,
                answer_length=len(answer),
            )

            return {
                "answer": answer,
                "source": source,
                "follow_up_prompt": None,  # Could be enhanced to detect when AI asks a question
            }

        except Exception as e:
            logger.warning("response_generation_fallback", error=str(e))
            fallback_answer = self._format_fallback_response(intent, tool_data, language, user_message)

            return {
                "answer": fallback_answer,
                "source": source,
                "follow_up_prompt": None,
            }

    def _format_fallback_response(
        self,
        intent: str,
        tool_data: dict | str | None,
        language: str,
        user_message: str,
    ) -> str:
        """Format a useful structured fallback response when LLM is unavailable."""
        is_ta = language == "ta"

        if intent == "greeting":
            return (
                "வணக்கம்! நான் ஹார்வெஸ்ட்லிங்க் வேளாண் உதவியாளர். அணை விவரங்கள், வானிலை, பயிர்கள் பற்றி என்னிடம் கேட்கலாம்!"
                if is_ta
                else "Hello! I am HarvestLink Agricultural Assistant. You can ask me about dam details, weather, or crops!"
            )

        if intent == "dam_details" and isinstance(tool_data, dict):
            if tool_data.get("type") == "dam_list":
                dams = tool_data.get("dams", [])
                if is_ta:
                    lines = ["தமிழ்நாடு முக்கிய அணைகளின் நிலவரம்:"]
                    for d in dams[:5]:
                        storage = d.get("current_storage_mcft", 0)
                        lines.append(f"• {d.get('dam_name_ta', d.get('dam_name'))}: கொள்ளளவு {d.get('capacity_mcft')} Mcft")
                    return "\n".join(lines)
                else:
                    lines = ["Main Dams in Tamil Nadu:"]
                    for d in dams[:5]:
                        lines.append(f"• {d.get('dam_name')}: Capacity {d.get('capacity_mcft')} Mcft")
                    return "\n".join(lines)
            else:
                name_ta = tool_data.get("dam_name_ta", tool_data.get("dam_name", "அணை"))
                name_en = tool_data.get("dam_name", "Dam")
                river = tool_data.get("river", "")
                district = tool_data.get("district", "")
                capacity = tool_data.get("capacity_mcft", "")
                cur_storage = tool_data.get("current_storage_mcft")
                water_lvl = tool_data.get("water_level_ft")
                
                if is_ta:
                    res = f"{name_ta} விவரங்கள்:\n"
                    res += f"• நதி: {river}\n"
                    res += f"• மாவட்டம்: {district}\n"
                    res += f"• மொத்த கொள்ளளவு: {capacity} Mcft\n"
                    if cur_storage:
                        res += f"• தற்போதைய சேமிப்பு: {round(cur_storage, 1)} Mcft\n"
                    if water_lvl:
                        res += f"• நீர்மட்டம்: {round(water_lvl, 1)} ft\n"
                    return res
                else:
                    res = f"{name_en} Details:\n"
                    res += f"• River: {river}\n"
                    res += f"• District: {district}\n"
                    res += f"• Capacity: {capacity} Mcft\n"
                    if cur_storage:
                        res += f"• Current Storage: {round(cur_storage, 1)} Mcft\n"
                    if water_lvl:
                        res += f"• Water Level: {round(water_lvl, 1)} ft\n"
                    return res

        if intent in ("weather_current", "weather_forecast") and isinstance(tool_data, dict):
            loc = tool_data.get("location", "Tamil Nadu")
            temp = tool_data.get("temperature")
            desc = tool_data.get("condition") or tool_data.get("weather")
            humidity = tool_data.get("humidity")
            if is_ta:
                return f"{loc} வானிலை நிலவரம்:\n• வெப்பநிலை: {temp or '30'}°C\n• சூழல்: {desc or 'மிதமான வானிலை'}\n• ஈரப்பதம்: {humidity or '70'}%"
            else:
                return f"Weather in {loc}:\n• Temp: {temp or '30'}°C\n• Condition: {desc or 'Clear'}\n• Humidity: {humidity or '70'}%"

        if intent == "crop_information" and isinstance(tool_data, dict):
            if "crops" in tool_data:
                crops_list = [c.get("name", "") for c in tool_data["crops"][:5]]
                crops_str = ", ".join([c for c in crops_list if c])
                return f"கிடைக்கக்கூடிய பயிர் தகவல்கள்: {crops_str}" if is_ta else f"Available crops info: {crops_str}"

        if intent == "general_agriculture":
            if is_ta:
                return "பொதுவான வேளாண் தகவல்களுக்கு, தயவுசெய்து உங்கள் கேள்வியை சுருக்கமாக கேட்கவும் அல்லது அணை மற்றும் வானிலை விவரங்களை கேட்கவும்."
            else:
                return "For general agriculture info, please keep your question brief, or ask me about specific dams, weather, or crops."

        # Default fallback
        if is_ta:
            return "மன்னிக்கவும், தகவல் தற்காலிகமாக பெற முடியவில்லை. பின்னர் மீண்டும் முயற்சிக்கவும்."
        else:
            return "Sorry, details are temporarily unavailable. Please try again later."
