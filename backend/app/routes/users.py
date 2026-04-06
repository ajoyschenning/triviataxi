"""User-related API endpoints."""
from fastapi import APIRouter, Depends, HTTPException, Header
from pydantic import BaseModel, Field
from firebase_admin import auth, firestore
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import List, Optional

security = HTTPBearer()

router = APIRouter(prefix="/users", tags=["users"])

# --- 1. Helper for Clean Auth ---
async def get_current_user_id(creds: HTTPAuthorizationCredentials = Depends(security)) -> str:
    """Decodes the Firebase token and returns the UID."""
    try:
        decoded_token = auth.verify_id_token(creds.credentials)
        return decoded_token['uid']
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid or expired token: {str(e)}")

# --- 2. Refined Models ---
class UserProfile(BaseModel):
    """User profile response model."""
    firebase_uid: str
    username: str
    email: str
    avatar_url: Optional[str] = None
    coins: int = 0
    miles: float = 0.0  
    owned: List[str] 
    sessions: List[str] 
    lifetime_games: int = 0
    win_streak: int = 0
    rank: Optional[int] = None

class UserCreate(BaseModel):
    """User creation request model."""
    username: str
    email: str

class UserUpdate(BaseModel):
    """User update request model."""
    username: str | None = None
    avatar_url: str | None = None
    user_id: str = Field(..., description="Firebase UID of the user to update")


class PurchaseRequest(BaseModel):
    """Purchase destination request model."""
    destination_id: str


class PurchaseResponse(BaseModel):
    """Purchase destination response model."""
    success: bool
    message: str
    new_coin_balance: int | None = None
    destination_id: str | None = None

class TriviaSessionResponse(BaseModel):
    id: str
    date: str
    miles: float
    coins: int
    was_perfect: bool
    timestamp: str



@router.post("/me")
async def create_user_profile(user: UserCreate, creds: HTTPAuthorizationCredentials = Depends(security)):
    """Creates a user document in Firestore after c Auth signup."""
    
    token = creds.credentials
    # 1. Authenticate user and get firebase_uid
    try:
        decoded_token = auth.verify_id_token(token)
        firebase_uid = decoded_token['uid']
    except Exception as e:
        print(f"🔥 FIREBASE ERROR: {e}") 
        raise HTTPException(status_code=401, detail=f"Invalid token: {str(e)}")

    try:
        db = firestore.client()
        user_ref = db.collection('users').document(firebase_uid)
        user_ref.set({
            'firebase_uid': firebase_uid,
            'email': user.email,
            'username': user.username,
            'avatar_url': None,
            'coins': 0,
            'miles': 0.0,
            'owned': ['Nashville_USA'],
            'sessions': [],
            'lifetime_games': 0,
            'win_streak': 0,
            'rank': None,
            'created_at': firestore.SERVER_TIMESTAMP
        })
        return {"status": "success", "uid": firebase_uid}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create user document : {str(e)}")


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
        coins=int(data.get('coins', 0)),
        miles=float(data.get('miles', 0.0)), 
        owned=data.get('owned', []),
        sessions=data.get('sessions', []),
        lifetime_games=int(data.get('lifetime_games', 0)),
        win_streak=int(data.get('win_streak', 0)),
        rank=data.get('rank')
    )


@router.put("/me")
async def update_user_profile(user_data: UserUpdate):
    """Update current user profile."""

    db = firestore.client()
    user_ref = db.collection('users').document(user_data.user_id)
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


@router.get("/{user_id}/owned_destinations")
async def get_owned_destinations(user_id: str):
    """Get list of destination IDs that a user owns."""
    try:
        db = firestore.client()
        user_doc = db.collection('users').document(user_id).get()
        
        if not user_doc.exists:
            raise HTTPException(status_code=404, detail="User not found")
        
        user_data = user_doc.to_dict() or {}
        owned = user_data.get('owned', [])
        
        return owned
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to fetch owned destinations")


@router.post("/{user_id}/purchase", response_model=PurchaseResponse)
async def purchase_destination(user_id: str, request: PurchaseRequest):
    """Purchase a destination for the user. Deducts coins and adds to owned list."""
    try:
        db = firestore.client()
        
        # 1. Get user document
        user_doc = db.collection('users').document(user_id).get()
        if not user_doc.exists:
            raise HTTPException(status_code=404, detail="User not found")
        
        user_data = user_doc.to_dict() or {}
        user_coins = float(user_data.get('coins', 0.0))
        user_owned = user_data.get('owned', [])
        
        # 2. Get destination document to get price
        dest_doc = db.collection('destinations').document(request.destination_id).get()
        if not dest_doc.exists:
            return PurchaseResponse(
                success=False,
                message="Destination not found"
            )
        
        dest_data = dest_doc.to_dict() or {}
        dest_price = int(dest_data.get('price', 0))
        
        # 3. Check if user already owns this destination
        if request.destination_id in user_owned:
            return PurchaseResponse(
                success=False,
                message="You already own this destination"
            )
        
        # 4. Check if user has enough coins
        if user_coins < dest_price:
            return PurchaseResponse(
                success=False,
                message=f"Insufficient coins. You need {dest_price} coins but have {user_coins}"
            )
        
        # 5. Deduct coins and add destination to owned list
        new_coin_balance = user_coins - dest_price
        user_owned.append(request.destination_id)
        
        db.collection('users').document(user_id).update({
            'coins': new_coin_balance,
            'owned': user_owned
        })
        
        return PurchaseResponse(
            success=True,
            message="Purchase successful",
            new_coin_balance=int(new_coin_balance),
            destination_id=request.destination_id
        )
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to complete purchase")


@router.get("/{user_id}/sessions", response_model=List[TriviaSessionResponse])
async def get_user_sessions(user_id: str):

    db = firestore.client()
    try:
        # 1. Get the User Document to find the session IDs
        user_ref = db.collection('users').document(user_id)
        user_doc = user_ref.get()
        
        if not user_doc.exists:
            raise HTTPException(status_code=404, detail="User not found")
        
        # 🚀 Grab the list of IDs (assuming the field is named 'session_ids')
        session_ids = user_doc.to_dict().get('sessions', [])
        print(session_ids)
        
        if not session_ids:
            return []

        # 2. Fetch all matching sessions at once
        recent_ids = session_ids[-10:] 
        
        sessions_query = db.collection('game_sessions').where(
        "__name__", 
        "in", 
        recent_ids).get()


        # 3. Map the results and sort them manually (since 'in' doesn't guarantee order)
        sessions_list = []

        for doc in sessions_query:
            data = doc.to_dict()
            raw_ts = data.get("completed_at") 
            timestamp_str = raw_ts.isoformat() if raw_ts else "N/A"
            date_str = raw_ts.strftime("%b %d") if raw_ts else "N/A"
            sessions_list.append({
                "id": data.get("session_id", ""),
                "date": date_str,
                "miles": float(data.get("miles_traveled", 0.0)),
                "coins": int(data.get("total_earnings", 0)),
                "was_perfect": data.get("strikes", False) == 0,
                "timestamp": timestamp_str
            })

        # Sort by timestamp descending so the newest is at the top
        sessions_list.sort(key=lambda x: str(x.get("timestamp", "")), reverse=True)
        
        return sessions_list

    except Exception as e:
        print(f"🚨 Error fetching sessions: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    
