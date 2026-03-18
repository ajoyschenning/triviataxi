"""Game session and question Firestore models."""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field


class GameSession(BaseModel):
    """Game session model for Firestore."""
    user_id: str = Field(..., description="User's Firebase UID")
    session_id: str = Field(..., description="Unique session ID")
    route_id: str = Field(..., description="route ID")
    total_earnings: float = Field(default=0.0, description="Total earnings in this session")
    strikes: int = Field(default=0, description="Number of strikes (max 3)")
    questions_answered: int = Field(default=0, description="Number of questions answered")
    completed_at: Optional[datetime] = Field(default=None, description="Session completion timestamp")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
