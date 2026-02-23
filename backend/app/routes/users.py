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
    coins: float
    miles: float
    owned: list[str]
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
def create_user_profile(user: UserCreate, authorization: str = Header(None)):
    """Creates a user document in Firestore after Firebase Auth signup."""
    
    if not authorization:
        raise HTTPException(status_code=401, detail="No token provided")
    token = authorization.replace("Bearer ", "")
    try:
        decoded_token = auth.verify_id_token(token)
        uid = decoded_token['uid']
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid token")

    try:
        db = firestore.client()
        user_ref = db.collection('users').document(uid)
        user_ref.set({
            'firebase_uid': uid,
            'email': user.email,
            'username': user.username,
            'avatar_url': None,
            'coins': 0.0,
            'miles': 0.0,
            'owned': [],
            'lifetime_games': 0,
            'win_streak': 0,
            'rank': None,
            'created_at': firestore.SERVER_TIMESTAMP
        })
        return {"status": "success", "uid": uid}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to create user document")


@router.get("/me", response_model=UserProfile)
async def get_user_profile(authorization: str = Header(None)):
    """Get current user profile and stats."""
    if not authorization:
        raise HTTPException(status_code=401, detail="No token provided")
    token = authorization.replace("Bearer ", "")
    try:
        decoded_token = auth.verify_id_token(token)
        uid = decoded_token['uid']
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

    db = firestore.client()
    doc = db.collection('users').document(uid).get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="User not found")
    data = doc.to_dict() or {}
    return UserProfile(
        firebase_uid=data.get('firebase_uid', uid),
        username=data.get('username', ''),
        email=data.get('email', ''),
        avatar_url=data.get('avatar_url'),
        total_earnings=float(data.get('total_earnings', 0.0)),
        lifetime_games=int(data.get('lifetime_games', 0)),
        win_streak=int(data.get('win_streak', 0)),
        rank=data.get('rank')
    )


@router.put("/me")
async def update_user_profile(user_data: UserUpdate, authorization: str = Header(None)):
    """Update current user profile."""
    if not authorization:
        raise HTTPException(status_code=401, detail="No token provided")
    token = authorization.replace("Bearer ", "")
    try:
        decoded_token = auth.verify_id_token(token)
        uid = decoded_token['uid']
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

    db = firestore.client()
    user_ref = db.collection('users').document(uid)
    updates = {}
    if user_data.username is not None:
        updates['username'] = user_data.username
    if user_data.avatar_url is not None:
        updates['avatar_url'] = user_data.avatar_url
    if not updates:
        return {"message": "No fields to update"}
    try:
        user_ref.update(updates)
        return {"message": "User profile updated successfully"}
    except Exception:
        raise HTTPException(status_code=500, detail="Failed to update user profile")
