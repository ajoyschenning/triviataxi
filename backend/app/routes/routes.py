from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.core.firestore import get_firestore_client

router = APIRouter(prefix="/destinations", tags=["destinations"])

class RouteCoordinates(BaseModel):
    short: list[list[float]]
    medium: list[list[float]]
    long: list[list[float]]

@router.get("/{destination_id}/{difficulty}", response_model=dict)
async def get_route_coordinates(destination_id: str, difficulty: str):
    """Return coordinates for a given destination and difficulty."""
    client = get_firestore_client()
    doc_ref = client.destinations_collection.document(destination_id)
    snapshot = doc_ref.get()
    
    print(f"DEBUG: Looking for destination: {destination_id}")
    print(f"DEBUG: Document exists: {snapshot.exists}")
    
    if not snapshot.exists:
        raise HTTPException(status_code=404, detail="Destination not found")
    data = snapshot.to_dict() or {}
    print(f"DEBUG: Document data keys: {list(data.keys())}")
    
    routes = data.get("routes", {})
    route = routes.get(difficulty)
    
    print(f"DEBUG: Available difficulties: {list(routes.keys())}")
    print(f"DEBUG: Looking for difficulty: {difficulty}")
    
    if not route:
        raise HTTPException(status_code=404, detail="Route not found for difficulty")
    
    return {
        difficulty: [
            [route["start"]["lat"], route["start"]["lon"]],
            [route["end"]["lat"], route["end"]["lon"]]
        ]
    }
