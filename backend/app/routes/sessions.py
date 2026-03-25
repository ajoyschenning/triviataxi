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
    earning_value: int

class GameCompletionPayload(BaseModel):
    user_id: str
    route_id: str
    total_earnings: int = 0
    strikes: int = 0
    questions_answered: int = 0

def calculate_earning_value(difficulty: str) -> int:
    """Calculate earning value based on difficulty level."""
    difficulty_lower = difficulty.lower()
    if difficulty_lower == "easy":
        return 5
    elif difficulty_lower == "medium":
        return 10
    elif difficulty_lower == "hard":
        return 15
    else:
        return 10  # Default to medium value

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
        firebase_uid=payload.user_id,
        journey_id=payload.route_id,
        total_earnings=payload.total_earnings,
        strikes=payload.strikes,
        questions_answered=payload.questions_answered,
        completed_at=datetime.now(),
        questions_fetched_count=0,
        current_question_index=0
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
    """Fetch a trivia question from the session's question pool.
    
    Implements a smart pooling strategy:
    - On first request, fetches 50 questions and stores them
    - On subsequent requests, returns questions from the pool
    - When reaching the end of the pool, automatically fetches another 50 questions
    """
    
    try:
        db = firestore.client()
        
        # Get the current session
        session_ref = db.collection('game_sessions').document(session_id)
        session_doc = session_ref.get()
        
        if not session_doc.exists:
            raise HTTPException(status_code=404, detail="Session not found")
        
        session_data = session_doc.to_dict()
        questions_fetched_count = session_data.get('questions_fetched_count', 0)
        current_question_index = session_data.get('current_question_index', 0)
        
        # Check if we need to fetch more questions
        if current_question_index >= questions_fetched_count:
            # Fetch a batch of 50 questions
            questions_batch = await TriviaService.get_questions_batch_from_open_trivia(
                amount=50,
                category=category,
                difficulty=difficulty
            )
            
            # Store all questions in the subcollection
            batch = db.batch()
            for idx, question_data in enumerate(questions_batch):
                question_id = str(uuid.uuid4())
                question_doc_ref = session_ref.collection('questions').document(question_id)
                
                batch.set(question_doc_ref, {
                    "question_id": question_id,
                    "question_text": question_data["question"],
                    "correct_answer": question_data["correct_answer"],
                    "incorrect_answers": question_data["incorrect_answers"],
                    "category": question_data["category"],
                    "difficulty": question_data["difficulty"],
                    "created_at": datetime.now(),
                    "question_index": questions_fetched_count + idx  # Store the pool index
                })
            
            # Update the session with new counts
            batch.update(session_ref, {
                'questions_fetched_count': questions_fetched_count + len(questions_batch)
            })
            
            batch.commit()
            
            # Update local variables
            questions_fetched_count += len(questions_batch)
        
        # Get the next question from the pool by index
        questions_snapshot = db.collection('game_sessions').document(session_id).collection('questions').where(
            'question_index', '==', current_question_index
        ).stream()
        
        question_doc = None
        for doc in questions_snapshot:
            question_doc = doc
            break
        
        if not question_doc:
            raise HTTPException(
                status_code=500,
                detail="Failed to retrieve question from pool"
            )
        
        question_data = question_doc.to_dict()
        
        # Increment current_question_index for next request
        session_ref.update({
            'current_question_index': current_question_index + 1
        })
        
        # Create the response
        response = QuestionResponse(
            question_id=question_data["question_id"],
            session_id=session_id,
            question_text=question_data["question_text"],
            correct_answer=question_data["correct_answer"],
            incorrect_answers=question_data["incorrect_answers"],
            category=question_data["category"],
            difficulty=question_data["difficulty"],
            earning_value=calculate_earning_value(question_data["difficulty"])
        )
        
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch question: {str(e)}"
        )


@router.get("/{session_id}/questions", response_model=List[QuestionResponse])
async def get_question_batch(
    session_id: str,
    limit: int = 50,
    category: Optional[str] = None,
    difficulty: Optional[str] = None,
    creds: HTTPAuthorizationCredentials = Depends(security)
):
    """Fetch a batch of trivia questions from the session's question pool.
    
    Returns multiple questions at once for efficient loading.
    - Automatically fetches new questions if the pool is running low
    - Returns up to `limit` questions (default 50)
    - Supports difficulty filtering
    """
    
    try:
        db = firestore.client()
        
        # Get the current session
        session_ref = db.collection('game_sessions').document(session_id)
        session_doc = session_ref.get()
        
        if not session_doc.exists:
            raise HTTPException(status_code=404, detail="Session not found")
        
        session_data = session_doc.to_dict()
        questions_fetched_count = session_data.get('questions_fetched_count', 0)
        current_question_index = session_data.get('current_question_index', 0)
        
        # Check if we need to fetch more questions
        # Fetch if we don't have enough questions to satisfy the limit request
        if current_question_index + limit > questions_fetched_count:
            # Fetch additional batches of 50 questions until we have enough
            while current_question_index + limit > questions_fetched_count:
                questions_batch = await TriviaService.get_questions_batch_from_open_trivia(
                    amount=50,
                    category=category,
                    difficulty=difficulty
                )
                
                # Store all questions in the subcollection
                batch_write = db.batch()
                for idx, question_data in enumerate(questions_batch):
                    question_id = str(uuid.uuid4())
                    question_doc_ref = session_ref.collection('questions').document(question_id)
                    
                    batch_write.set(question_doc_ref, {
                        "question_id": question_id,
                        "question_text": question_data["question"],
                        "correct_answer": question_data["correct_answer"],
                        "incorrect_answers": question_data["incorrect_answers"],
                        "category": question_data["category"],
                        "difficulty": question_data["difficulty"],
                        "created_at": datetime.now(),
                        "question_index": questions_fetched_count + idx
                    })
                
                # Update the session with new count
                batch_write.update(session_ref, {
                    'questions_fetched_count': questions_fetched_count + len(questions_batch)
                })
                
                batch_write.commit()
                questions_fetched_count += len(questions_batch)
        
        # Get the next `limit` questions from the pool by index
        questions_list = []
        for i in range(limit):
            question_index = current_question_index + i
            
            # Stop if we've reached the end
            if question_index >= questions_fetched_count:
                break
            
            questions_snapshot = db.collection('game_sessions').document(session_id).collection('questions').where(
                'question_index', '==', question_index
            ).stream()
            
            question_doc = None
            for doc in questions_snapshot:
                question_doc = doc
                break
            
            if question_doc:
                question_data = question_doc.to_dict()
                response_question = QuestionResponse(
                    question_id=question_data["question_id"],
                    session_id=session_id,
                    question_text=question_data["question_text"],
                    correct_answer=question_data["correct_answer"],
                    incorrect_answers=question_data["incorrect_answers"],
                    category=question_data["category"],
                    difficulty=question_data["difficulty"],
                    earning_value=calculate_earning_value(question_data["difficulty"])
                )
                questions_list.append(response_question)
        
        if not questions_list:
            raise HTTPException(
                status_code=500,
                detail="Failed to retrieve questions from pool"
            )
        
        # Return the batch as a list
        return questions_list
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch question batch: {str(e)}"
        )


