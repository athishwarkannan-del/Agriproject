"""
HarvestLink Backend - Conversation Service.

Manages conversation history and context for follow-up questions.
"""

import uuid
from datetime import datetime, timezone
from typing import Optional
from app.core.database import get_supabase_client
from app.core.logging import get_logger
from app.models.enums import ConversationRole

logger = get_logger(__name__)

# Number of previous messages to include as context
CONTEXT_WINDOW_SIZE = 10


class ConversationService:
    """Manages conversation sessions and message history."""

    def __init__(self):
        self.db = get_supabase_client()

    def create_conversation(self, user_id: str) -> str:
        """Create a new conversation session and return its ID."""
        conversation_id = str(uuid.uuid4())
        try:
            self.db.table("conversations").insert({
                "id": conversation_id,
                "user_id": user_id,
                "created_at": datetime.now(timezone.utc).isoformat(),
            }).execute()
            logger.info("conversation_created", conversation_id=conversation_id, user_id=user_id)
        except Exception as e:
            logger.error("conversation_create_failed", error=str(e))
            # Return ID anyway — we can still process the query without persisting
        return conversation_id

    def add_message(
        self,
        conversation_id: str,
        role: ConversationRole,
        content: str,
        metadata: Optional[dict] = None,
    ) -> None:
        """Add a message to the conversation history."""
        try:
            self.db.table("conversation_messages").insert({
                "id": str(uuid.uuid4()),
                "conversation_id": conversation_id,
                "role": role.value,
                "content": content,
                "metadata": metadata or {},
                "created_at": datetime.now(timezone.utc).isoformat(),
            }).execute()
        except Exception as e:
            logger.error("message_save_failed", conversation_id=conversation_id, error=str(e))

    def get_conversation_context(self, conversation_id: str) -> list[dict]:
        """
        Retrieve recent messages from a conversation for AI context.

        Returns the last N messages to help the AI understand follow-up questions
        like "அது" (it/that) referring to previous topics.
        """
        try:
            result = (
                self.db.table("conversation_messages")
                .select("role, content, metadata")
                .eq("conversation_id", conversation_id)
                .order("created_at", desc=False)
                .limit(CONTEXT_WINDOW_SIZE)
                .execute()
            )
            return result.data if result.data else []
        except Exception as e:
            logger.error("context_fetch_failed", conversation_id=conversation_id, error=str(e))
            return []

    def get_or_create_conversation(self, user_id: str, conversation_id: Optional[str] = None) -> str:
        """Get existing conversation or create a new one."""
        if conversation_id:
            # Verify the conversation exists and belongs to the user
            try:
                result = (
                    self.db.table("conversations")
                    .select("id")
                    .eq("id", conversation_id)
                    .eq("user_id", user_id)
                    .execute()
                )
                if result.data:
                    return conversation_id
            except Exception as e:
                logger.warning("conversation_verify_failed", error=str(e))

        return self.create_conversation(user_id)
