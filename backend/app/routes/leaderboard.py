"""Leaderboard API endpoints."""
from http.client import HTTPException

from app.routes.users import get_current_user_id
from fastapi import APIRouter, Depends, HTTPException, Query 
from pydantic import BaseModel
from typing import List
from firebase_admin import auth, firestore
from app.models.leaderboard import LeaderboardEntry
from datetime import datetime, timezone



router = APIRouter(prefix="/leaderboards", tags=["leaderboards"])



@router.get("/leaderboard", response_model=List[LeaderboardEntry])
async def get_leaderboard(
    timeframe: str = Query("all_time", regex="^(all_time|weekly)$"), # 🚀 Validation
    limit: int = 25
):
    try:
        db = firestore.client()
        now = datetime.now(timezone.utc)
        
        if timeframe == "weekly":
            # 🚀 Calculate the current week ID (e.g., "2026-W14")
            week_id = now.strftime("%Y-W%U") 
            
            # Query the dedicated weekly stats collection
            query = db.collection('weekly_stats')\
                .where('week_id', '==', week_id)\
                .order_by('miles', direction=firestore.Query.DESCENDING)\
                .limit(limit)
        else:
            # Default All-Time logic
            query = db.collection('users')\
                .order_by('miles', direction=firestore.Query.DESCENDING)\
                .limit(limit)

        users_query = query.stream()
        leaderboard = []
        
        for i, doc in enumerate(users_query):
            data = doc.to_dict()
            
            leaderboard.append(LeaderboardEntry(
                entry_id=doc.id,
                firebase_uid=data.get('firebase_uid', ''),
                username=data.get('username', 'Unknown Driver'),
                # Note: both collections use 'miles' for the field name
                miles_traveled=float(data.get('miles', 0.0)),
                lifetime_games=int(data.get('lifetime_games', 0)),
                rank=i + 1,
                timeframe=timeframe,
                updated_at=now.strftime('%Y-%m-%dT%H:%M:%SZ')
            ))

        return leaderboard

    except Exception as e:
        print(f"🚨 Leaderboard Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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