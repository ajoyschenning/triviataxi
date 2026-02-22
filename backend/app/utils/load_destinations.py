"""
Utility script to load destination data into Firestore.

Usage:
    python -m app.utils.load_destinations

This will load destinations.json from the backend/data/ directory.
"""
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from app.services.data_loader import load_data_from_default_path


def main():
    """Execute the data loading process."""
    print("Loading destinations into Firestore...")
    print("-" * 50)
    
    try:
        result = load_data_from_default_path()
        
        print("-" * 50)
        print(f"✓ Process completed!")
        print(f"  Total destinations: {result['total']}")
        print(f"  Successfully loaded: {result['loaded']}")
        print(f"  Failed: {result['failed']}")
        
        if result['errors']:
            print("\nErrors encountered:")
            for error in result['errors']:
                print(f"  - {error}")
        
        return 0 if result['success'] else 1
        
    except FileNotFoundError as e:
        print(f"✗ Error: {e}")
        print("\nMake sure you have:")
        print("  1. Created the 'backend/data/' folder")
        print("  2. Placed 'destinations.json' in that folder")
        return 1
    except Exception as e:
        print(f"✗ Unexpected error: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
