"""Game session-related API endpoints."""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
import uuid
from datetime import datetime
from fastapi import Header
from firebase_admin import auth, firestore
from app.models.session import GameSession
from fastapi import Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer()
router = APIRouter(prefix="/sessions", tags=["sessions"])


# class TripMetadata(BaseModel):
#     """Trip metadata model."""
#     total_distance: float
#     checkpoints: int
#     start_location: str
#     end_location: str


# class Question(BaseModel):
#     """Trivia question model."""
#     question_id: str
#     text: str
#     correct_answer: str
#     incorrect_answers: List[str]
#     category: str
#     difficulty: str
#     earning_value: float



class SessionResponse(BaseModel):
     """Game session response model."""
     session_id: str
 #    trip_metadata: TripMetadata
 #    current_question: Question
#     current_earnings: float
 #    strikes: int
#     progress_percent: float


# class AnswerSubmission(BaseModel):
#     """Answer submission model."""
#     answer: str


# class AnswerResponse(BaseModel):
#     """Answer evaluation response model."""
#     is_correct: bool
#     earned_amount: float
#     current_strikes: int
#     current_earnings: float
#     progress_percent: float
#     next_question: Question | None
#     session_ended: bool
#     session_result: dict | None


# 🚀 1. This tells FastAPI to accept a JSON Body!
class GameCompletionPayload(BaseModel):
    user_id: str
    route_id: str
    total_earnings: int = 0
    strikes: int = 0
    questions_answered: int = 0

@router.post("", response_model=SessionResponse)
async def save_session(
    payload: GameCompletionPayload, # 🚀 2. Inject the model here
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




# @router.get("/{session_id}", response_model=SessionResponse)
# async def get_session(session_id: str):
#     """Get current session state."""
#     db = firestore.client()
#     # 1. Fetch session data
#     session_doc = db.collection('game_sessions').document(session_id).get()
#     if not session_doc.exists:
#         raise HTTPException(status_code=404, detail="Session not found")
#     session_data = session_doc.to_dict()

#     # 2. Fetch current question
#     current_index = session_data.get("current_question_index", 0)
#     questions = list(db.collection('questions').where('session_id', '==', session_id).stream())
#     if not questions:
#         raise HTTPException(status_code=404, detail="No questions found for session")
#     # Sort questions by creation or index if needed; here, just use order returned
#     current_question_doc = questions[current_index] if current_index < len(questions) else questions[0]
#     current_question_data = current_question_doc.to_dict()

#     # 3. Build response
#     trip_metadata = TripMetadata(
#         total_distance=session_data.get("total_distance", 100.0),
#         checkpoints=5,  # Adjust if you store this in session
#         start_location="Downtown",  # Adjust if you store this in session
#         end_location="Airport"      # Adjust if you store this in session
#     )
#     current_question = Question(
#         question_id=current_question_data["question_id"],
#         text=current_question_data["question_text"],
#         correct_answer=current_question_data["correct_answer"],
#         incorrect_answers=current_question_data["incorrect_answers"],
#         category=current_question_data.get("category", "General"),
#         difficulty=current_question_data.get("difficulty", "medium"),
#         earning_value=current_question_data.get("earning_value", 10.0)
#     )
#     return SessionResponse(
#         session_id=session_id,
#         trip_metadata=trip_metadata,
#         current_question=current_question,
#         current_earnings=session_data.get("total_earnings", 0.0),
#         strikes=session_data.get("strikes", 0),
#         progress_percent=(session_data.get("distance_traveled", 0.0) / session_data.get("total_distance", 100.0)) * 100
#     )


# @router.post("/{session_id}/answer", response_model=AnswerResponse)
# async def submit_answer(session_id: str, submission: AnswerSubmission):
#     """Submit an answer for the current question."""
#     db = firestore.client()
#     # 1. Fetch session data
#     session_ref = db.collection('game_sessions').document(session_id)
#     session_doc = session_ref.get()
#     if not session_doc.exists:
#         raise HTTPException(status_code=404, detail="Session not found")
#     session_data = session_doc.to_dict()

#     # 2. Fetch current question
#     current_index = session_data.get("current_question_index", 0)
#     questions = list(db.collection('questions').where('session_id', '==', session_id).stream())
#     if not questions or current_index >= len(questions):
#         raise HTTPException(status_code=404, detail="No more questions in session")
#     current_question_doc = questions[current_index]
#     current_question_data = current_question_doc.to_dict()

#     # 3. Validate answer
#     is_correct = submission.answer.strip().lower() == current_question_data["correct_answer"].strip().lower()
#     earned_amount = current_question_data.get("earning_value", 10.0) if is_correct else 0.0
#     strikes = session_data.get("strikes", 0) + (0 if is_correct else 1)
#     current_earnings = session_data.get("total_earnings", 0.0) + earned_amount
#     questions_answered = session_data.get("questions_answered", 0) + 1
#     next_index = current_index + 1

#     # 4. Check if session ended
#     session_ended = (next_index >= len(questions)) or (strikes >= 3)
#     session_result = None
#     next_question = None

#     if not session_ended:
#         next_question_doc = questions[next_index]
#         next_question_data = next_question_doc.to_dict()
#         next_question = Question(
#             question_id=next_question_data["question_id"],
#             text=next_question_data["question_text"],
#             correct_answer=next_question_data["correct_answer"],
#             incorrect_answers=next_question_data["incorrect_answers"],
#             category=next_question_data.get("category", "General"),
#             difficulty=next_question_data.get("difficulty", "medium"),
#             earning_value=next_question_data.get("earning_value", 10.0)
#         )

#     # 5. Update session in Firestore
#     update_data = {
#         "strikes": strikes,
#         "total_earnings": current_earnings,
#         "questions_answered": questions_answered,
#         "current_question_index": next_index if not session_ended else current_index,
#         "is_completed": session_ended,
#         "distance_traveled": (questions_answered / len(questions)) * session_data.get("total_distance", 100.0)
#     }
#     session_ref.update(update_data)

#     # 6. Progress percent
#     progress_percent = (update_data["distance_traveled"] / session_data.get("total_distance", 100.0)) * 100

#     # 7. If session ended, build result
#     if session_ended:
#         session_result = {
#             "total_earnings": current_earnings,
#             "strikes": strikes,
#             "questions_answered": questions_answered,
#             "completed": next_index >= len(questions)
#         }

#     return AnswerResponse(
#         is_correct=is_correct,
#         earned_amount=earned_amount,
#         current_strikes=strikes,
#         current_earnings=current_earnings,
#         progress_percent=progress_percent,
#         next_question=next_question,
#         session_ended=session_ended,
#         session_result=session_result
#     )


# @router.post("/{session_id}/skip")
# async def skip_question(session_id: str):
#     """Skip current question with penalty."""
#     db = firestore.client()
#     session_ref = db.collection('game_sessions').document(session_id)
#     session_doc = session_ref.get()
#     if not session_doc.exists:
#         raise HTTPException(status_code=404, detail="Session not found")
#     session_data = session_doc.to_dict()

#     current_index = session_data.get("current_question_index", 0)
#     strikes = session_data.get("strikes", 0) + 1
#     questions_answered = session_data.get("questions_answered", 0) + 1

#     questions = list(db.collection('questions').where('session_id', '==', session_id).stream())
#     next_index = current_index + 1
#     session_ended = (next_index >= len(questions)) or (strikes >= 3)

#     update_data = {
#         "strikes": strikes,
#         "questions_answered": questions_answered,
#         "current_question_index": next_index if not session_ended else current_index,
#         "is_completed": session_ended,
#         "distance_traveled": (questions_answered / len(questions)) * session_data.get("total_distance", 100.0)
#     }
#     session_ref.update(update_data)

#     if session_ended:
#         return {"message": "Session ended due to skips or strikes."}
#     else:
#         return {"message": "Question skipped. Next question loaded.", "strikes": strikes}


# @router.post("/{session_id}/end")
# async def end_session(session_id: str):
#     """End session early and return final score."""
#     db = firestore.client()
#     session_ref = db.collection('game_sessions').document(session_id)
#     session_doc = session_ref.get()
#     if not session_doc.exists:
#         raise HTTPException(status_code=404, detail="Session not found")
#     session_data = session_doc.to_dict()

#     # Mark session as completed
#     update_data = {
#         "is_completed": True
#     }
#     session_ref.update(update_data)

#     # Prepare result summary
#     result = {
#         "total_earnings": session_data.get("total_earnings", 0.0),
#         "strikes": session_data.get("strikes", 0),
#         "questions_answered": session_data.get("questions_answered", 0),
#         "completed": True
#     }
#     return {"message": "Session ended early.", "session_result": result}


# @router.get("/{session_id}/question", response_model=Question)
# async def get_current_question(session_id: str):
#     """Get the current question for a session."""
#     db = firestore.client()
#     session_doc = db.collection('game_sessions').document(session_id).get()
#     if not session_doc.exists:
#         raise HTTPException(status_code=404, detail="Session not found")
#     session_data = session_doc.to_dict()

#     current_index = session_data.get("current_question_index", 0)
#     questions = list(db.collection('questions').where('session_id', '==', session_id).stream())
#     if not questions or current_index >= len(questions):
#         raise HTTPException(status_code=404, detail="No current question found")
#     current_question_doc = questions[current_index]
#     current_question_data = current_question_doc.to_dict()

#     return Question(
#         question_id=current_question_data["question_id"],
#         text=current_question_data["question_text"],
#         correct_answer=current_question_data["correct_answer"],
#         incorrect_answers=current_question_data["incorrect_answers"],
#         category=current_question_data.get("category", "General"),
#         difficulty=current_question_data.get("difficulty", "medium"),
#         earning_value=current_question_data.get("earning_value", 10.0)
#     )


# @router.post("/{session_id}/hint")
# async def generate_hint(session_id: str):
#     """Generate AI-powered hint for current question."""
#     # TODO: Implement OpenAI hint generation
#     return {"hint": "Here's a helpful hint..."}
