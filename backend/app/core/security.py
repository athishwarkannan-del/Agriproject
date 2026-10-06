"""
HarvestLink Backend - Security & Authentication.

JWT validation middleware for Supabase Auth tokens.
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError
from app.config import get_settings
from app.core.logging import get_logger
from typing import Optional

logger = get_logger(__name__)

# Bearer token security scheme
security = HTTPBearer()


def decode_jwt_token(token: str) -> dict:
    """
    Decode and validate a Supabase JWT token.

    Supabase uses the ANON key as the JWT secret for token verification.
    In production, use the JWT secret from Supabase project settings.
    """
    settings = get_settings()
    try:
        # Supabase JWT tokens are signed with the JWT secret
        # For development, we verify with the anon key
        # For production, use the proper JWT secret from Supabase dashboard
        payload = jwt.decode(
            token,
            settings.supabase_anon_key,
            algorithms=["HS256"],
            audience="authenticated",
        )
        return payload
    except JWTError as e:
        logger.warning("jwt_decode_failed", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """
    Extract and validate the current user from the JWT token.

    Returns the decoded JWT payload containing user information.
    """
    token = credentials.credentials
    payload = decode_jwt_token(token)

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token: missing user ID",
        )

    return {
        "user_id": user_id,
        "email": payload.get("email"),
        "phone": payload.get("phone"),
        "role": payload.get("role", "authenticated"),
    }


async def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(
        HTTPBearer(auto_error=False)
    ),
) -> Optional[dict]:
    """Get current user if token is provided, otherwise return None."""
    if credentials is None:
        return None
    try:
        return await get_current_user(credentials)
    except HTTPException:
        return None
