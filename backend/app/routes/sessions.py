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
async def create_session(journey_id: str, 
                         creds: HTTPAuthorizationCredentials = Depends(security)):
    """Create a new trivia trip session."""
    token = creds.credentials
    # 1. Authenticate user and get firebase_uid
    try:
        decoded_token = auth.verify_id_token(token)
        firebase_uid = decoded_token['uid']
    except Exception as e:
        print(f"🔥 FIREBASE ERROR: {e}") 
        raise HTTPException(status_code=401, detail=f"Invalid token: {str(e)}")
    
    # 2. Generate session ID and create session in Firestore
    session_id = str(uuid.uuid4())
    db = firestore.client()
    
    session_data = GameSession(
        session_id=session_id,
        firebase_uid=firebase_uid,
        journey_id=journey_id,
        total_earnings=0.0,
        strikes=0,
        questions_answered=0,
        is_completed=False,
        distance_traveled=0.0,
        total_distance=100.0,
        created_at=datetime.now(),
    )
    
    db.collection('game_sessions').document(session_id).set(session_data.model_dump())
    
    # 3. Fetch initial question from TriviaService (fetch one question at a time)
    questions_data = await TriviaService.get_questions_from_open_trivia()
    
    # Store the first question in Firestore
    q = questions_data[0]
    normalized_q = await TriviaService.normalize_question_format(q)
    first_question_data = QuestionModel(
        question_id=str(uuid.uuid4()),
        session_id=session_id,
        question_text=normalized_q['question'],
        correct_answer=normalized_q['correct_answer'],
        incorrect_answers=normalized_q['incorrect_answers'],
        category=normalized_q.get('category', 'General'),
        difficulty=normalized_q.get('difficulty', 'medium'),
        earning_value=10.0 * (1 if normalized_q.get('difficulty') == 'easy' else 2 if normalized_q.get('difficulty') == 'medium' else 3)
    )
    db.collection('questions').document(first_question_data.question_id).set(first_question_data.model_dump())
    
    # 4. Build trip metadata (you may want to fetch this from a journeys collection)
    trip_metadata = TripMetadata(
        total_distance=100.0,
        checkpoints=5,
        start_location="Downtown",
        end_location="Airport"
    )
    
    # 5. Build initial question response
    current_question = Question(
        question_id=first_question_data.question_id,
        text=first_question_data.question_text,
        correct_answer=first_question_data.correct_answer,
        incorrect_answers=first_question_data.incorrect_answers,
        category=first_question_data.category,
        difficulty=first_question_data.difficulty,
        earning_value=first_question_data.earning_value
    )
    
    # 6. Return session response
    return SessionResponse(
        session_id=session_id,
        trip_metadata=trip_metadata,
        current_question=current_question,
        current_earnings=0.0,
        strikes=0,
        progress_percent=0.0
    )


@router.get("/{session_id}", response_model=SessionResponse)
async def get_session(session_id: str):
    """Get current session state."""
    db = firestore.client()
    # 1. Fetch session data
    session_doc = db.collection('game_sessions').document(session_id).get()
    if not session_doc.exists:
        raise HTTPException(status_code=404, detail="Session not found")
    session_data = session_doc.to_dict()

    # 2. Fetch the latest question for this session
    questions = list(db.collection('questions').where('session_id', '==', session_id).stream())
    if not questions:
        raise HTTPException(status_code=404, detail="No questions found for session")
    # Get the most recently created question (last one in the list)
    current_question_doc = questions[-1]
    current_question_data = current_question_doc.to_dict()

    # 3. Build response
    trip_metadata = TripMetadata(
        total_distance=session_data.get("total_distance", 100.0),
        checkpoints=5,  # Adjust if you store this in session
        start_location="Downtown",  # Adjust if you store this in session
        end_location="Airport"      # Adjust if you store this in session
    )
    current_question = Question(
        question_id=current_question_data["question_id"],
        text=current_question_data["question_text"],
        correct_answer=current_question_data["correct_answer"],
        incorrect_answers=current_question_data["incorrect_answers"],
        category=current_question_data.get("category", "General"),
        difficulty=current_question_data.get("difficulty", "medium"),
        earning_value=current_question_data.get("earning_value", 10.0)
    )
    return SessionResponse(
    session_data = GameSession(    
        session_id=session_id,
        trip_metadata=trip_metadata,
        current_question=current_question,
        current_earnings=session_data.get("total_earnings", 0.0),
        strikes=session_data.get("strikes", 0),
        progress_percent=min(100, (session_data.get("questions_answered", 0) / 10) * 100)  # Rough estimate
    )


@router.post("/{session_id}/answer", response_model=AnswerResponse)
async def submit_answer(session_id: str, submission: AnswerSubmission):
    """Submit an answer for the current question."""
    db = firestore.client()
    # 1. Fetch session data
    session_ref = db.collection('game_sessions').document(session_id)
    session_doc = session_ref.get()
    if not session_doc.exists:
        raise HTTPException(status_code=404, detail="Session not found")
    session_data = session_doc.to_dict()

    # 2. Fetch the latest question (most recently created)
    questions = list(db.collection('questions').where('session_id', '==', session_id).stream())
    if not questions:
        raise HTTPException(status_code=404, detail="No questions found for session")
    current_question_doc = questions[-1]  # Get the most recent question
    current_question_data = current_question_doc.to_dict()

    # 3. Validate answer
    is_correct = submission.answer.strip().lower() == current_question_data["correct_answer"].strip().lower()
    earned_amount = current_question_data.get("earning_value", 10.0) if is_correct else 0.0
    strikes = session_data.get("strikes", 0) + (0 if is_correct else 1)
    current_earnings = session_data.get("total_earnings", 0.0) + earned_amount
    questions_answered = session_data.get("questions_answered", 0) + 1

    # 4. Check if session ended (3 strikes = game over)
    session_ended = strikes >= 3
    session_result = None
    next_question = None

    if not session_ended:
        # Fetch next question from API
        question_data = await TriviaService.get_questions_from_open_trivia()
        q = question_data[0]
        normalized_q = await TriviaService.normalize_question_format(q)
        
        next_question_data = QuestionModel(
            question_id=str(uuid.uuid4()),
            session_id=session_id,
            question_text=normalized_q['question'],
            correct_answer=normalized_q['correct_answer'],
            incorrect_answers=normalized_q['incorrect_answers'],
            category=normalized_q.get('category', 'General'),
            difficulty=normalized_q.get('difficulty', 'medium'),
            earning_value=10.0 * (1 if normalized_q.get('difficulty') == 'easy' else 2 if normalized_q.get('difficulty') == 'medium' else 3)
        )
        db.collection('questions').document(next_question_data.question_id).set(next_question_data.model_dump())
        
        next_question = Question(
            question_id=next_question_data.question_id,
            text=next_question_data.question_text,
            correct_answer=next_question_data.correct_answer,
            incorrect_answers=next_question_data.incorrect_answers,
            category=next_question_data.category,
            difficulty=next_question_data.difficulty,
            earning_value=next_question_data.earning_value
        )

    # 5. Update session in Firestore
    update_data = {
        "strikes": strikes,
        "total_earnings": current_earnings,
        "questions_answered": questions_answered,
        "is_completed": session_ended,
    }
    session_ref.update(update_data)

    # 6. Progress percent (estimate based on time/questions answered, not total questions)
    progress_percent = min(100, (questions_answered / 10) * 100)  # Rough estimate

    # 7. If session ended, build result
    if session_ended:
        session_result = {
            "total_earnings": current_earnings,
            "strikes": strikes,
            "questions_answered": questions_answered,
            "completed": True
        }

    return AnswerResponse(
        is_correct=is_correct,
        earned_amount=earned_amount,
        current_strikes=strikes,
        current_earnings=current_earnings,
        progress_percent=progress_percent,
        next_question=next_question,
        session_ended=session_ended,
        session_result=session_result
    )


@router.post("/{session_id}/skip")
async def skip_question(session_id: str):
    """Skip current question with penalty."""
    db = firestore.client()
    session_ref = db.collection('game_sessions').document(session_id)
    session_doc = session_ref.get()
    if not session_doc.exists:
        raise HTTPException(status_code=404, detail="Session not found")
    session_data = session_doc.to_dict()

    strikes = session_data.get("strikes", 0) + 1
    questions_answered = session_data.get("questions_answered", 0) + 1

    # Check if session ended (3 strikes = game over)
    session_ended = strikes >= 3

    update_data = {
        "strikes": strikes,
        "questions_answered": questions_answered,
        "is_completed": session_ended
    }
    session_ref.update(update_data)

    if session_ended:
        return {"message": "Session ended due to strikes.", "strikes": strikes}
    else:
        # Fetch next question from API
        question_data = await TriviaService.get_questions_from_open_trivia()
        q = question_data[0]
        normalized_q = await TriviaService.normalize_question_format(q)
        
        next_question_data = QuestionModel(
            question_id=str(uuid.uuid4()),
            session_id=session_id,
            question_text=normalized_q['question'],
            correct_answer=normalized_q['correct_answer'],
            incorrect_answers=normalized_q['incorrect_answers'],
            category=normalized_q.get('category', 'General'),
            difficulty=normalized_q.get('difficulty', 'medium'),
            earning_value=10.0 * (1 if normalized_q.get('difficulty') == 'easy' else 2 if normalized_q.get('difficulty') == 'medium' else 3)
        )
        db.collection('questions').document(next_question_data.question_id).set(next_question_data.model_dump())
        return {"message": "Question skipped. Next question loaded.", "strikes": strikes}


@router.post("/{session_id}/end")
async def end_session(session_id: str):
    """End session early and return final score."""
    db = firestore.client()
    session_ref = db.collection('game_sessions').document(session_id)
    session_doc = session_ref.get()
    if not session_doc.exists:
        raise HTTPException(status_code=404, detail="Session not found")
    session_data = session_doc.to_dict()

    # Mark session as completed
    update_data = {
        "is_completed": True
    }
    session_ref.update(update_data)

    # Prepare result summary
    result = {
        "total_earnings": session_data.get("total_earnings", 0.0),
        "strikes": session_data.get("strikes", 0),
        "questions_answered": session_data.get("questions_answered", 0),
        "completed": True
    }
    return {"message": "Session ended early.", "session_result": result}


@router.get("/{session_id}/question", response_model=Question)
async def get_current_question(session_id: str):
    """Get the current question for a session."""
    db = firestore.client()
    session_doc = db.collection('game_sessions').document(session_id).get()
    if not session_doc.exists:
        raise HTTPException(status_code=404, detail="Session not found")
    
    # Get the most recently created question for this session
    questions = list(db.collection('questions').where('session_id', '==', session_id).stream())
    if not questions:
        raise HTTPException(status_code=404, detail="No current question found")
    
    current_question_doc = questions[-1]  # Get the most recent question
    current_question_data = current_question_doc.to_dict()

    return Question(
        question_id=current_question_data["question_id"],
        text=current_question_data["question_text"],
        correct_answer=current_question_data["correct_answer"],
        incorrect_answers=current_question_data["incorrect_answers"],
        category=current_question_data.get("category", "General"),
        difficulty=current_question_data.get("difficulty", "medium"),
        earning_value=current_question_data.get("earning_value", 10.0)
    )


@router.post("/{session_id}/hint")
async def generate_hint(session_id: str):
    """Generate AI-powered hint for current question."""
    # TODO: Implement OpenAI hint generation
    return {"hint": "Here's a helpful hint..."}
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
