"""
HarvestLink Backend - Authentication API.

Handles user registration and login via Supabase Auth.
"""

from fastapi import APIRouter, HTTPException, status
from app.core.database import get_supabase_client
from app.core.logging import get_logger
from app.core.exceptions import get_error_message
from app.models.schemas import RegisterRequest, LoginRequest, AuthResponse, FarmerProfileCreate

logger = get_logger(__name__)

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=AuthResponse)
async def register(request: RegisterRequest):
    """Register a new farmer account."""
    db = get_supabase_client()

    try:
        # Create user via Supabase Auth
        credentials = {}
        if request.email:
            credentials["email"] = request.email
            credentials["password"] = request.password
        elif request.phone:
            credentials["phone"] = request.phone
            credentials["password"] = request.password
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email or phone number is required.",
            )

        auth_response = db.auth.sign_up(credentials)

        if not auth_response.user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Registration failed. Please try again.",
            )

        user_id = auth_response.user.id

        # Create farmer profile
        try:
            db.table("farmer_profiles").insert({
                "user_id": user_id,
                "name": request.name,
                "preferred_language": request.preferred_language.value,
            }).execute()
        except Exception as e:
            logger.error("profile_creation_failed", user_id=user_id, error=str(e))

        logger.info("user_registered", user_id=user_id)

        return AuthResponse(
            access_token=auth_response.session.access_token if auth_response.session else "",
            refresh_token=auth_response.session.refresh_token if auth_response.session else "",
            user_id=user_id,
            message="Registration successful. Welcome to HarvestLink!",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error("registration_failed", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Registration failed. Please try again.",
        )


@router.post("/login", response_model=AuthResponse)
async def login(request: LoginRequest):
    """Login an existing farmer."""
    db = get_supabase_client()

    try:
        credentials = {}
        if request.email:
            credentials["email"] = request.email
            credentials["password"] = request.password
        elif request.phone:
            credentials["phone"] = request.phone
            credentials["password"] = request.password
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email or phone number is required.",
            )

        auth_response = db.auth.sign_in_with_password(credentials)

        if not auth_response.user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials.",
            )

        logger.info("user_logged_in", user_id=auth_response.user.id)

        return AuthResponse(
            access_token=auth_response.session.access_token,
            refresh_token=auth_response.session.refresh_token,
            user_id=auth_response.user.id,
            message="Login successful.",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error("login_failed", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Login failed. Please check your credentials.",
        )


@router.post("/refresh")
async def refresh_token(refresh_token: str):
    """Refresh an expired JWT token."""
    db = get_supabase_client()

    try:
        auth_response = db.auth.refresh_session(refresh_token)

        return {
            "access_token": auth_response.session.access_token,
            "refresh_token": auth_response.session.refresh_token,
        }
    except Exception as e:
        logger.error("token_refresh_failed", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token refresh failed. Please login again.",
        )
