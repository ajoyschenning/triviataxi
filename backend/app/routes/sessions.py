"""Game session-related API endpoints."""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import uuid
from datetime import datetime
from fastapi import Header
from firebase_admin import auth, firestore
from app.models.session import GameSession, Question
from app.services.trivia_service import TriviaService
from fastapi import Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer()
router = APIRouter(prefix="/sessions", tags=["sessions"])

class SessionResponse(BaseModel):
     """Game session response model."""
     session_id: str

class QuestionResponse(BaseModel):
    """Question response model."""
    question_id: str
    session_id: str
    question_text: str
    correct_answer: str
    incorrect_answers: List[str]
    category: str
    difficulty: str

class GameCompletionPayload(BaseModel):
    user_id: str
    route_id: str
    total_earnings: int = 0
    strikes: int = 0
    questions_answered: int = 0

@router.post("", response_model=SessionResponse)
async def save_session(
    payload: GameCompletionPayload,
    creds: HTTPAuthorizationCredentials = Depends(security)
):
    """Saves a new trivia trip session."""
    
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
    
    return SessionResponse(
        session_id=session_id
    )


@router.get("/{session_id}/question", response_model=QuestionResponse)
async def get_question(
    session_id: str,
    category: Optional[str] = None,
    difficulty: Optional[str] = None,
    creds: HTTPAuthorizationCredentials = Depends(security)
):
    """Fetch a single trivia question from OpenTrivia API for a session."""
    
    try:
        # Fetch question from OpenTrivia API
        question_data = await TriviaService.get_question_from_open_trivia(
            category=category,
            difficulty=difficulty
        )
        
        # Generate a unique question ID
        question_id = str(uuid.uuid4())
        
        # Create the response
        response = QuestionResponse(
            question_id=question_id,
            session_id=session_id,
            question_text=question_data["question"],
            correct_answer=question_data["correct_answer"],
            incorrect_answers=question_data["incorrect_answers"],
            category=question_data["category"],
            difficulty=question_data["difficulty"]
        )
        
        # Optionally save the question to Firestore for record-keeping
        db = firestore.client()
        db.collection('game_sessions').document(session_id).collection('questions').document(question_id).set({
            "question_id": question_id,
            "question_text": question_data["question"],
            "correct_answer": question_data["correct_answer"],
            "incorrect_answers": question_data["incorrect_answers"],
            "category": question_data["category"],
            "difficulty": question_data["difficulty"],
            "created_at": datetime.now()
        })
        
        return response
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch question: {str(e)}"
        )

