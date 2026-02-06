"""User-related API endpoints."""
from fastapi import APIRouter, Header, HTTPException
from pydantic import BaseModel
from firebase_admin import auth, firestore

router = APIRouter(prefix="/users", tags=["users"])


class UserProfile(BaseModel):
    """User profile response model."""
    firebase_uid: str
    username: str
    email: str
    avatar_url: str | None
    total_earnings: float
    lifetime_games: int
    win_streak: int
    rank: int | None


class UserCreate(BaseModel):
    """User creation request model."""
    username: str
    email: str


class UserUpdate(BaseModel):
    """User update request model."""
    username: str | None = None
    avatar_url: str | None = None


@router.post("/me")
def create_user_profile(user: UserProfile, authorization: str = Header(None)):
    """Creates a user document in Firestore after Firebase Auth signup."""
    
    # 1. Check for the ID Token
    if not authorization:
        raise HTTPException(status_code=401, detail="No token provided")
    
    token = authorization.replace("Bearer ", "")
    
    try:
        # 2. Verify the token with Firebase to get the real UID
        decoded_token = auth.verify_id_token(token)
        uid = decoded_token['uid']
        
        # 3. Write to Firestore
        db = firestore.client()
        user_ref = db.collection('users').document(uid)
        
        # Set the initial data
        user_ref.set({
            'firebase_uid': uid,
            'email': user.email,
            'username': user.username,
            'score': 0,
            'fares_collected': 0,
            'created_at': firestore.SERVER_TIMESTAMP
        })
        
        return {"status": "success", "uid": uid}
        
    except Exception as e:
        print(f"Auth Error: {e}")
        raise HTTPException(status_code=401, detail="Invalid token")


@router.get("/me", response_model=UserProfile)
async def get_user_profile():
    """Get current user profile and stats."""
    # TODO: Implement user profile retrieval
    return {}


@router.put("/me")
async def update_user_profile(user_data: UserUpdate):
    """Update current user profile."""
    # TODO: Implement user profile update
    return {"message": "User profile updated successfully"}
