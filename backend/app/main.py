"""
HarvestLink Backend - Main Entrypoint.

FastAPI application configuration and router registration.
"""

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import time

from app.config import get_settings
from app.core.logging import setup_logging, get_logger
from app.core.exceptions import HarvestLinkException
from app.api.v1 import auth, assistant, farmer, dams, weather, disease, crops

# Initialize structured logging
setup_logging()
logger = get_logger(__name__)

settings = get_settings()

app = FastAPI(
    title="HarvestLink API",
    description="Backend API for the HarvestLink Agricultural Assistant.",
    version="1.0.0",
    docs_url="/docs" if settings.app_debug else None,
    redoc_url="/redoc" if settings.app_debug else None,
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    """Add X-Process-Time header and log request."""
    start_time = time.time()
    
    # Generate request ID
    import uuid
    request_id = str(uuid.uuid4())
    
    import structlog
    structlog.contextvars.clear_contextvars()
    structlog.contextvars.bind_contextvars(
        request_id=request_id,
        method=request.method,
        path=request.url.path,
    )
    
    try:
        response = await call_next(request)
        process_time = time.time() - start_time
        response.headers["X-Process-Time"] = str(process_time)
        
        logger.info(
            "request_completed",
            status_code=response.status_code,
            duration=process_time,
        )
        return response
    except Exception as e:
        process_time = time.time() - start_time
        logger.error(
            "request_failed",
            error=str(e),
            duration=process_time,
            exc_info=True
        )
        raise


@app.exception_handler(HarvestLinkException)
async def harvestlink_exception_handler(request: Request, exc: HarvestLinkException):
    """Handle custom HarvestLink exceptions to return friendly bilingual messages."""
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,  # Default, can be overridden by specific exceptions if needed
        content={"detail": exc.user_message, "error_key": exc.error_key},
    )


# Register API routers
app.include_router(auth.router, prefix="/api/v1")
app.include_router(farmer.router, prefix="/api/v1")
app.include_router(assistant.router, prefix="/api/v1")
app.include_router(dams.router, prefix="/api/v1")
app.include_router(weather.router, prefix="/api/v1")
app.include_router(disease.router, prefix="/api/v1")
app.include_router(crops.router, prefix="/api/v1")


@app.get("/health", tags=["Health"])
async def health_check():
    """Application health check endpoint."""
    return {
        "status": "healthy",
        "version": app.version,
        "environment": settings.app_env,
    }
