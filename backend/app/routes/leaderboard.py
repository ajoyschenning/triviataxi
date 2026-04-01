"""Leaderboard API endpoints."""
from http.client import HTTPException

from app.routes.users import get_current_user_id
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import List
from firebase_admin import auth, firestore
from app.models.leaderboard import LeaderboardEntry
from datetime import datetime, timezone

# ... inside your loop ...


router = APIRouter(prefix="/leaderboards", tags=["leaderboards"])


@router.get("/leaderboard", response_model=List[LeaderboardEntry])
async def get_leaderboard(limit: int = 25):
    """
    Fetches the top users ranked by total miles traveled.
    """
    try:
        db = firestore.client()
        
        # 1. Query Firestore: Sort by miles (descending) and limit results
        users_query = db.collection('users')\
            .order_by('miles', direction=firestore.Query.DESCENDING)\
            .limit(limit)\
            .stream()

        leaderboard = []
        
        # 2. Loop through results and manually assign the rank
        for i, doc in enumerate(users_query):
            data = doc.to_dict()
            
            # Create the UserProfile object
            leaderboard_entry  = LeaderboardEntry(
                    entry_id=doc.id,
                    firebase_uid=data.get('firebase_uid', ''),
                    username=data.get('username', 'Unknown Driver'),
                    miles_traveled=float(data.get('miles', 0.0)),
                    lifetime_games=int(data.get('lifetime_games', 0)),
                    rank=i + 1,
                    timeframe="all_time",
                    # 🚀 FIX: Use timezone-aware UTC and format it specifically for Swift
                    updated_at=datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
)       
            leaderboard.append(leaderboard_entry)

        return leaderboard

    except Exception as e:
        print(f"🚨 Leaderboard Error: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch leaderboard")

@router.get("/my-rank")
async def get_my_rank(uid: str = Depends(get_current_user_id)):
    """
    Calculates the current user's rank relative to all other players.
    """
    db = firestore.client()
    user_doc = db.collection('users').document(uid).get()
    
    if not user_doc.exists:
        raise HTTPException(status_code=404, detail="User not found")
    
    user_miles = user_doc.to_dict().get('miles', 0.0)
    
    # Count how many users have MORE miles than the current user
    # Rank = (Count of people with more miles) + 1
    rank_query = db.collection('users').where('miles', '>', user_miles).count().get()
    
    return {"rank": rank_query[0][0].value + 1}