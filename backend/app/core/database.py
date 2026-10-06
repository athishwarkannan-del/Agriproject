"""
HarvestLink Backend - Database Client.

Initializes and manages the Supabase client connection.
"""

from supabase import create_client, Client
from app.config import get_settings
from app.core.logging import get_logger
from functools import lru_cache

logger = get_logger(__name__)


@lru_cache()
def get_supabase_client() -> Client:
    """Get the Supabase client (service role for backend operations)."""
    settings = get_settings()
    try:
        client = create_client(
            settings.supabase_url,
            settings.supabase_service_role_key,
        )
        logger.info("supabase_client_initialized", url=settings.supabase_url)
        return client
    except Exception as e:
        logger.warning(f"supabase_client_failed: {e}. Using MockClient for Dev Mode.")
        class MockTable:
            def insert(self, *args, **kwargs): return self
            def select(self, *args, **kwargs): return self
            def eq(self, *args, **kwargs): return self
            def order(self, *args, **kwargs): return self
            def limit(self, *args, **kwargs): return self
            def execute(self, *args, **kwargs):
                class MockResult:
                    data = []
                return MockResult()
        
        class MockStorageBucket:
            def upload(self, *args, **kwargs): return None
            def get_public_url(self, *args, **kwargs): return "mock_url"
            
        class MockStorage:
            def from_(self, name): return MockStorageBucket()
        
        class MockClient:
            def table(self, name): return MockTable()
            @property
            def storage(self): return MockStorage()
            
        return MockClient()


@lru_cache()
def get_supabase_anon_client() -> Client:
    """Get the Supabase client with anonymous key (for user-scoped operations)."""
    settings = get_settings()
    client = create_client(
        settings.supabase_url,
        settings.supabase_anon_key,
    )
    return client
