"""Game session-related API endpoints."""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List

router = APIRouter(prefix="/sessions", tags=["sessions"])


class TripMetadata(BaseModel):
    """Trip metadata model."""
    total_distance: float
    checkpoints: int
    start_location: str
    end_location: str


class Question(BaseModel):
    """Trivia question model."""
    question_id: str
    text: str
    correct_answer: str
    incorrect_answers: List[str]
    category: str
    difficulty: str
    earning_value: float


class SessionResponse(BaseModel):
    """Game session response model."""
    session_id: str
    trip_metadata: TripMetadata
    current_question: Question
    current_earnings: float
    strikes: int
    progress_percent: float


class AnswerSubmission(BaseModel):
    """Answer submission model."""
    answer: str


class AnswerResponse(BaseModel):
    """Answer evaluation response model."""
    is_correct: bool
    earned_amount: float
    current_strikes: int
    current_earnings: float
    progress_percent: float
    next_question: Question | None
    session_ended: bool
    session_result: dict | None


@router.post("", response_model=SessionResponse)
async def create_session(journey_id: str):
    """Create a new trivia trip session."""
    # TODO: Implement session creation with trivia delivery
    return {}


@router.get("/{session_id}", response_model=SessionResponse)
async def get_session(session_id: str):
    """Get current session state."""
    # TODO: Implement session state retrieval
    return {}


@router.post("/{session_id}/answer", response_model=AnswerResponse)
async def submit_answer(session_id: str, submission: AnswerSubmission):
    """Submit an answer for the current question."""
    # TODO: Implement answer validation and scoring
    return {}


@router.post("/{session_id}/skip")
async def skip_question(session_id: str):
    """Skip current question with penalty."""
    # TODO: Implement skip logic
    return {"message": "Question skipped"}


@router.post("/{session_id}/end")
async def end_session(session_id: str):
    """End session early and return final score."""
    # TODO: Implement session termination
    return {}


@router.get("/{session_id}/question", response_model=Question)
async def get_current_question(session_id: str):
    """Get the current question for a session."""
    # TODO: Implement question retrieval
    return {}


@router.post("/{session_id}/hint")
async def generate_hint(session_id: str):
    """Generate AI-powered hint for current question."""
    # TODO: Implement OpenAI hint generation
    return {"hint": "Here's a helpful hint..."}
