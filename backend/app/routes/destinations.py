"""Destination-related API endpoints."""
from typing import List

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.core.firestore import get_firestore_client

router = APIRouter(prefix="/destinations", tags=["destinations"])


class DestinationSummary(BaseModel):
    id: str
    city: str | None = None
    country: str | None = None
    price: float | None = None
    image_url: str | None = None


@router.get("/", response_model=List[DestinationSummary])
async def list_destinations():
    """Return all destinations with minimal fields for the shop grid."""
    client = get_firestore_client()
    docs = client.destinations_collection.stream()

    results: List[dict] = []
    for doc in docs:
        data = doc.to_dict() or {}
        results.append({
            "id": doc.id,
            "city": data.get("city"),
            "country": data.get("country"),
            "price": data.get("price"),
            "image_url": data.get("image_url"),
        })

    return results


@router.get("/{destination_id}")
async def get_destination(destination_id: str):
    """Return full destination details for a given destination id."""
    client = get_firestore_client()
    doc_ref = client.destinations_collection.document(destination_id)
    snapshot = doc_ref.get()
    if not snapshot.exists:
        raise HTTPException(status_code=404, detail="Destination not found")

    data = snapshot.to_dict() or {}
    data["id"] = snapshot.id
    return data


@router.get("/{destination_id}/{difficulty}")
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
        "origin_lat": route["start"]["lat"],
        "origin_lng": route["start"]["lon"],
        "destination_lat": route["end"]["lat"],
        "destination_lng": route["end"]["lon"]
    }
