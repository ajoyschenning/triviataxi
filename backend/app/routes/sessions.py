"""Game session-related API endpoints."""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
import uuid
from datetime import datetime
from fastapi import Header
from firebase_admin import auth, firestore
from app.models.session import GameSession, Question as QuestionModel
from app.services.trivia_service import TriviaService
from fastapi import Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer()
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
async def save_session(
    payload: GameCompletionPayload,
    creds: HTTPAuthorizationCredentials = Depends(security)
):
    """Saves a new trivia trip session."""
    try: 
        session_id = str(uuid.uuid4())
        db = firestore.client()

        session_data = GameSession(    
            session_id=session_id,
            user_id=payload.user_id,
            route_id=payload.route_id,
            total_earnings=payload.total_earnings,
            strikes=payload.strikes,
            questions_answered=payload.questions_answered,
            completed_at=datetime.now()
        )

        db.collection('game_sessions').document(session_id).set(session_data.model_dump())
        
        user_doc = db.collection('users').document(payload.user_id).get()
        if not user_doc.exists:
            raise HTTPException(status_code=404, detail="User not found")
        
        user_data = user_doc.to_dict() or {}
        user_coins = float(user_data.get('coins', 0.0))
        user_sessions = user_data.get('sessions', [])

        new_coin_balance = user_coins + payload.total_earnings
        user_sessions.append(session_id)

        db.collection('users').document(payload.user_id).update({
            'coins': new_coin_balance,
            'sessions': user_sessions
        })
        
        return SessionResponse(
            session_id=session_id
        )
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to update user: " + str(e))


@router.get("/{session_id}/question", response_model=Question)
async def get_question(
    session_id: str,
    creds: HTTPAuthorizationCredentials = Depends(security)
):
    """Fetch a trivia question for a game session."""
    try:
        # Fetch a question from the Open Trivia Database
        questions_data = await TriviaService.get_questions_from_open_trivia()
        
        if not questions_data:
            raise HTTPException(status_code=500, detail="Failed to fetch question from trivia API")
        
        # Extract the first (and only) question from the response
        question_data = questions_data[0]
        
        # Create a question ID (using UUID)
        question_id = str(uuid.uuid4())
        
        # For now, use a default earning value based on difficulty
        difficulty = question_data.get("difficulty", "medium").lower()
        earning_value = {
            "easy": 5.0,
            "medium": 10.0,
            "hard": 20.0
        }.get(difficulty, 10.0)
        
        # Return the question in the expected format
        return Question(
            question_id=question_id,
            text=question_data.get("question", ""),
            correct_answer=question_data.get("correct_answer", ""),
            incorrect_answers=question_data.get("incorrect_answers", []),
            category=question_data.get("category", "General"),
            difficulty=difficulty,
            earning_value=earning_value
        )
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch question: {str(e)}")
