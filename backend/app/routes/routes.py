from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.core.firestore import get_firestore_client

router = APIRouter(prefix="/routes", tags=["routes"])

class RouteCoordinates(BaseModel):
    origin_lat: float
    origin_lng: float
    destination_lat: float
    destination_lng: float

@router.get("/{destination_id}/{difficulty}", response_model=RouteCoordinates)
async def get_route_coordinates(destination_id: str, difficulty: str):
    """Return coordinates for a given destination and difficulty."""
    client = get_firestore_client()
    doc_ref = client.destinations_collection.document(destination_id)
    snapshot = doc_ref.get()
    if not snapshot.exists:
        raise HTTPException(status_code=404, detail="Destination not found")
    data = snapshot.to_dict() or {}
    routes = data.get("routes", {})
    route = routes.get(difficulty)
    if not route:
        raise HTTPException(status_code=404, detail="Route not found for difficulty")
    return RouteCoordinates(
        origin_lat=route["origin_lat"],
        origin_lng=route["origin_lng"],
        destination_lat=route["destination_lat"],
        destination_lng=route["destination_lng"]
    )
