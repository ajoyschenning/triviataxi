"""Routes for data management operations."""
from fastapi import APIRouter, HTTPException
from app.services.data_loader import load_data_from_default_path

router = APIRouter(prefix="/api/data", tags=["data"])


@router.post("/load-destinations")
async def load_destinations_endpoint():
    """
    Load destinations from the default data directory into Firestore.
    
    **Note**: This endpoint should be protected in production.
    
    Returns:
        dict: Status of the loading operation
        
    Example Response:
        {
            "success": true,
            "loaded": 2,
            "failed": 0,
            "total": 2,
            "message": "Successfully loaded all destinations"
        }
    """
    try:
        result = load_data_from_default_path()
        
        message = f"Successfully loaded {result['loaded']} destinations"
        if result['failed'] > 0:
            message = f"Loaded {result['loaded']} destinations with {result['failed']} failures"
        
        return {
            "success": result['success'],
            "loaded": result['loaded'],
            "failed": result['failed'],
            "total": result['total'],
            "message": message,
            "errors": result['errors'] if result['errors'] else []
        }
        
    except FileNotFoundError:
        raise HTTPException(
            status_code=404,
            detail="destinations.json not found. Place the file in backend/data/destinations.json"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error loading destinations: {str(e)}"
        )
