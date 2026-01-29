"""Leaderboard Firestore model."""
from datetime import datetime
from pydantic import BaseModel, Field


class LeaderboardEntry(BaseModel):
    """Leaderboard entry model for Firestore."""
    
    entry_id: str = Field(..., description="Unique entry ID")
    firebase_uid: str = Field(..., description="User's Firebase UID")
    username: str = Field(..., description="User's username")
    total_earnings: float = Field(..., description="User's total earnings")
    lifetime_games: int = Field(default=0, description="Total games played")
    rank: int = Field(..., description="Current rank position")
    timeframe: str = Field(..., description="Timeframe: weekly, monthly, all_time")
    updated_at: datetime = Field(default_factory=datetime.utcnow, description="Last update timestamp")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
