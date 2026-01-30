"""User-related API endpoints."""
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

router = APIRouter(prefix="/users", tags=["users"])


class UserProfile(BaseModel):
    """User profile response model."""
    firebase_uid: str
    username: str
    email: str
    avatar_url: str | None
    total_earnings: float
    lifetime_games: int
    win_streak: int
    rank: int | None


class UserCreate(BaseModel):
    """User creation request model."""
    username: str
    email: str


class UserUpdate(BaseModel):
    """User update request model."""
    username: str | None = None
    avatar_url: str | None = None


@router.post("/me")
async def create_user(user_data: UserCreate):
    """Create a new user profile on first login."""
    # TODO: Implement user creation with Firebase UID
    return {"message": "User created successfully"}


@router.get("/me", response_model=UserProfile)
async def get_user_profile():
    """Get current user profile and stats."""
    # TODO: Implement user profile retrieval
    return {}


@router.put("/me")
async def update_user_profile(user_data: UserUpdate):
    """Update current user profile."""
    # TODO: Implement user profile update
    return {"message": "User profile updated successfully"}
