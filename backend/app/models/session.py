"""Game session and question Firestore models."""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field


class Question(BaseModel):
    """Trivia question model for Firestore."""
    
    question_id: str = Field(..., description="Unique question ID")
    session_id: str = Field(..., description="Parent session ID")
    question_text: str = Field(..., description="The trivia question")
    correct_answer: str = Field(..., description="Correct answer text")
    incorrect_answers: List[str] = Field(..., description="List of incorrect answers")
    category: str = Field(..., description="Question category")
    difficulty: str = Field(..., description="Difficulty level: easy, medium, hard")
    user_answer: Optional[str] = Field(None, description="User's submitted answer")
    is_correct: Optional[bool] = Field(None, description="Whether answer was correct")
    earning_value: float = Field(default=0.0, description="Points earned for correct answer")
    created_at: datetime = Field(default_factory=datetime.utcnow, description="Question creation timestamp")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class GameSession(BaseModel):
    """Game session model for Firestore."""
    
    session_id: str = Field(..., description="Unique session ID")
    firebase_uid: str = Field(..., description="User's Firebase UID")
    journey_id: str = Field(..., description="Journey/route ID")
    total_earnings: float = Field(default=0.0, description="Total earnings in this session")
    strikes: int = Field(default=0, description="Number of strikes (max 3)")
    questions_answered: int = Field(default=0, description="Number of questions answered")
    current_question_index: int = Field(default=0, description="Current question index")
    is_completed: bool = Field(default=False, description="Whether session is completed")
    distance_traveled: float = Field(default=0.0, description="Distance traveled (0-100%)")
    total_distance: float = Field(default=100.0, description="Total trip distance")
    created_at: datetime = Field(default_factory=datetime.utcnow, description="Session start timestamp")
    ended_at: Optional[datetime] = Field(None, description="Session end timestamp")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
