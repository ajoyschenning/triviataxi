# """Service for loading initial data into Firestore."""
# import json
# import os
# from pathlib import Path
# from app.core.firestore import FirestoreClient


# class DataLoader:
#     """Load JSON data files into Firestore collections."""
    
#     def __init__(self):
#         """Initialize the data loader with Firestore client."""
#         self.db = FirestoreClient().get_db()
    
#     def load_destinations(self, json_file_path: str) -> dict:
#         """
#         Load destinations from JSON file into Firestore.
        
#         Args:
#             json_file_path: Path to the destinations JSON file
            
#         Returns:
#             Dictionary with load status and statistics
            
#         Raises:
#             FileNotFoundError: If the JSON file doesn't exist
#             json.JSONDecodeError: If the JSON is invalid
#         """
#         if not os.path.exists(json_file_path):
#             raise FileNotFoundError(f"JSON file not found: {json_file_path}")
        
#         # Read the JSON file
#         with open(json_file_path, 'r', encoding='utf-8') as f:
#             destinations_data = json.load(f)
        
#         # Load each destination into Firestore
#         loaded_count = 0
#         failed_count = 0
#         errors = []

#         destinations = destinations_data.get("destinations", destinations_data)

        
#         for destination_id, destination_data in destinations_data.items():
#             try:
#                 # Validate required fields
#                 if "city" not in destination_data or "country" not in destination_data:
#                     errors.append(f"{destination_id}: Missing city or country field")
#                     failed_count += 1
#                     continue
                
#                 # Create document in 'destinations' collection
#                 self.db.collection("destinations").document(destination_id).set(destination_data)
#                 loaded_count += 1
#                 print(f"✓ Loaded: {destination_data.get('city')}, {destination_data.get('country')}")
                
#             except Exception as e:
#                 errors.append(f"{destination_id}: {str(e)}")
#                 failed_count += 1
#                 print(f"✗ Failed to load {destination_id}: {str(e)}")
        
#         result = {
#             "success": failed_count == 0,
#             "loaded": loaded_count,
#             "failed": failed_count,
#             "total": len(destinations_data),
#             "errors": errors if errors else None
#         }
        
#         return result


# def load_data_from_default_path() -> dict:
#     """
#     Load destinations from the default data directory.
    
#     Default path: backend/data/destinations.json
    
#     Returns:
#         Dictionary with load status and statistics
#     """
#     # Get the path to the data directory
#     backend_dir = Path(__file__).parent.parent.parent
#     json_file_path = backend_dir / "data" / "destinations.json"
    
#     loader = DataLoader()
#     return loader.load_destinations(str(json_file_path))
"""Service for loading initial data into Firestore."""
import json
import os
from pathlib import Path
from app.core.firestore import FirestoreClient


class DataLoader:
    """Load JSON data files into Firestore collections."""
    
    def __init__(self):
        """Initialize the data loader with Firestore client."""
        self.db = FirestoreClient().get_db()
    
    def load_destinations(self, json_file_path: str) -> dict:
        """
        Load destinations from JSON file into Firestore.
        
        Args:
            json_file_path: Path to the destinations JSON file
            
        Returns:
            Dictionary with load status and statistics
            
        Raises:
            FileNotFoundError: If the JSON file doesn't exist
            json.JSONDecodeError: If the JSON is invalid
        """
        if not os.path.exists(json_file_path):
            raise FileNotFoundError(f"JSON file not found: {json_file_path}")
        
        # Read the JSON file
        with open(json_file_path, 'r', encoding='utf-8') as f:
            destinations_data = json.load(f)
        
        # Load each destination into Firestore
        loaded_count = 0
        failed_count = 0
        errors = []

        destinations = destinations_data.get("destinations", destinations_data)

        for destination_id, destination_data in destinations.items():
            try:
                # Validate required fields
                if "city" not in destination_data or "country" not in destination_data:
                    errors.append(f"{destination_id}: Missing city or country field")
                    failed_count += 1
                    continue
                
                # Create document in 'destinations' collection
                self.db.collection("destinations").document(destination_id).set(destination_data)
                loaded_count += 1
                print(f"✓ Loaded: {destination_data.get('city')}, {destination_data.get('country')}")
                
            except Exception as e:
                errors.append(f"{destination_id}: {str(e)}")
                failed_count += 1
                print(f"✗ Failed to load {destination_id}: {str(e)}")
        
        result = {
            "success": failed_count == 0,
            "loaded": loaded_count,
            "failed": failed_count,
            "total": len(destinations),
            "errors": errors if errors else None
        }
        
        return result


def load_data_from_default_path() -> dict:
    """
    Load destinations from the default data directory.
    
    Default path: backend/data/destinations.json
    
    Returns:
        Dictionary with load status and statistics
    """
    # Get the path to the data directory
    backend_dir = Path(__file__).parent.parent.parent
    json_file_path = backend_dir / "data" / "destinations.json"
    
    loader = DataLoader()
    return loader.load_destinations(str(json_file_path))