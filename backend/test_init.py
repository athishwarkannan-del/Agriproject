import os
import sys

# Mock env vars before importing app
os.environ["SUPABASE_URL"] = "http://localhost:54321"
os.environ["SUPABASE_ANON_KEY"] = "test_key"
os.environ["SUPABASE_SERVICE_ROLE_KEY"] = "test_key"
os.environ["GEMINI_API_KEY"] = "test_key"
os.environ["APP_ENV"] = "testing"

from fastapi.testclient import TestClient

try:
    from app.main import app
    print("[SUCCESS] Successfully imported FastAPI app")
    
    client = TestClient(app)
    response = client.get("/health")
    
    if response.status_code == 200:
        print(f"[SUCCESS] Health check passed: {response.json()}")
    else:
        print(f"[ERROR] Health check failed with status {response.status_code}: {response.text}")
        sys.exit(1)
        
except Exception as e:
    print(f"[ERROR] Failed to initialize app: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
