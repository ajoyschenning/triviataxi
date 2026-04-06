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
class SessionResponse(BaseModel):
     """Game session response model."""
     session_id: str

class GameCompletionPayload(BaseModel):
    user_id: str
    route_id: str
    total_earnings: int = 0
    strikes: int = 0
    miles_traveled: float = 0.0
    questions_answered: int = 0


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
            miles_traveled=payload.miles_traveled,
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
        new_miles = float(user_data.get('miles', 0.0)) + payload.miles_traveled
        user_sessions.append(session_id)

        db.collection('users').document(payload.user_id).update({
            'coins': new_coin_balance,
            'sessions': user_sessions,
            'miles': new_miles,
            'lifetime_games': int(user_data.get('lifetime_games', 0)) + 1
        })

        week_id = datetime.now().strftime("%Y-W%U")
        weekly_doc_id = f"{payload.user_id}_{week_id}"

        db.collection('weekly_stats').document(weekly_doc_id).set({
            'firebase_uid': payload.user_id,
            'username': user_data.get('username', 'Unknown Driver'),
            'week_id': week_id,
            'miles': firestore.Increment(payload.miles_traveled),
        }, merge=True)
        
        return SessionResponse(
            session_id=session_id
        )
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to update user: " + str(e))

        

