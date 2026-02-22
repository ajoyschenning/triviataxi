"""
Utility script to patch image_url into existing Firestore destination documents.

Usage:
    python -m app.utils.update_image_urls

This will read destinations_with_images.json from the backend/data/ directory
and add the image_url field to each existing Firestore document WITHOUT
overwriting any other fields.
"""
import sys
import json
import os
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from app.core.firestore import FirestoreClient


def update_image_urls(json_file_path: str) -> dict:
    """
    Read image_url fields from JSON and patch them into existing Firestore documents.

    Uses .update() (not .set()) so all existing route/price/city data is preserved.

    Args:
        json_file_path: Path to destinations_with_images.json

    Returns:
        Dictionary with update status and statistics
    """
    if not os.path.exists(json_file_path):
        raise FileNotFoundError(f"JSON file not found: {json_file_path}")

    with open(json_file_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    destinations = data.get("destinations", data)

    db = FirestoreClient().get_db()
    updated_count = 0
    failed_count = 0
    errors = []

    for destination_id, destination_data in destinations.items():
        image_url = destination_data.get("image_url")

        if not image_url:
            errors.append(f"{destination_id}: No image_url field found in JSON, skipping")
            failed_count += 1
            continue

        try:
            # .update() patches only the image_url field — all other document
            # fields (city, country, price, routes, etc.) are left untouched
            db.collection("destinations").document(destination_id).update({
                "image_url": image_url
            })
            updated_count += 1
            print(f"✓ Updated: {destination_id}")

        except Exception as e:
            errors.append(f"{destination_id}: {str(e)}")
            failed_count += 1
            print(f"✗ Failed: {destination_id} — {str(e)}")

    return {
        "success": failed_count == 0,
        "updated": updated_count,
        "failed": failed_count,
        "total": len(destinations),
        "errors": errors if errors else None,
    }


def main():
    """Execute the image URL update process."""
    print("Patching image_url into Firestore destination documents...")
    print("-" * 50)

    backend_dir = Path(__file__).parent.parent.parent
    json_file_path = backend_dir / "data" / "destinations_with_images.json"

    try:
        result = update_image_urls(str(json_file_path))

        print("-" * 50)
        print(f"✓ Process completed!")
        print(f"  Total destinations: {result['total']}")
        print(f"  Successfully updated: {result['updated']}")
        print(f"  Failed: {result['failed']}")

        if result["errors"]:
            print("\nErrors encountered:")
            for error in result["errors"]:
                print(f"  - {error}")

        return 0 if result["success"] else 1

    except FileNotFoundError as e:
        print(f"✗ Error: {e}")
        print("\nMake sure you have placed 'destinations_with_images.json' in backend/data/")
        return 1
    except Exception as e:
        print(f"✗ Unexpected error: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
