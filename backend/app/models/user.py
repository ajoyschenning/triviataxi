"""User Firestore model."""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class User(BaseModel):
    """User model for Firestore storage."""
    
    firebase_uid: str = Field(..., description="Firebase Authentication UID")
    username: str = Field(..., description="Unique username")
    email: str = Field(..., description="User email")
    avatar_url: Optional[str] = Field(None, description="Avatar image URL")

    coins: int = Field(default=0, description="Current coin balance")
    miles: float = Field(default=0.0, description="Total miles traveled (Hero Metric)")  

    owned: list[str] = Field(default_factory=list, description="Destination IDs owned by the user")
    sessions: list[str] = Field(default_factory=list, description="Users session IDs")
    
    lifetime_games: int = Field(default=0, description="Total games played")
    win_streak: int = Field(default=0, description="Current win streak")
    rank: Optional[int] = Field(None, description="Current leaderboard rank")

    created_at: datetime = Field(default_factory=datetime.utcnow, description="Account creation timestamp")
    updated_at: datetime = Field(default_factory=datetime.utcnow, description="Last update timestamp")
    is_active: bool = Field(default=True, description="Account active status")
    

    class Config:
        from_attributes = True

        json_encoders = {
            datetime: lambda v: v.isoformat()
        }