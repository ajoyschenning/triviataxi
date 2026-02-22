# Destinations Data Loading Guide

## Directory Structure Setup

You need to create a `data` folder in the `backend` directory. Here's the structure:

```
backend/
├── data/
│   └── destinations.json    ← Place your JSON file here
├── app/
├── main.py
└── requirements.txt
```

## Folder Creation

1. **Create the `backend/data/` folder** (you need to do this manually):
   - Navigate to your `backend` directory
   - Create a new folder named `data`

## JSON File Format

Your `destinations.json` file should follow this structure:

```json
{
  "Montreal_Canada": {
    "city": "Montreal",
    "country": "Canada",
    "price": 300,
    "routes": {
      "long": {
        "start": {
          "lat": 45.5017,
          "lon": -73.5673,
          "location": "Old Montreal / Notre-Dame Basilica"
        },
        "end": {
          "lat": 45.5529,
          "lon": -73.7155,
          "location": "McGill University"
        },
        "length": 7.998498731
      },
      "medium": {
        "start": { "lat": 0, "lon": 0, "location": "..." },
        "end": { "lat": 0, "lon": 0, "location": "..." },
        "length": 0
      },
      "short": {
        "start": { "lat": 0, "lon": 0, "location": "..." },
        "end": { "lat": 0, "lon": 0, "location": "..." },
        "length": 0
      }
    }
  },
  "Toronto_Canada": {
    "city": "Toronto",
    "country": "Canada",
    "price": 250,
    "routes": { ... }
  }
}
```

## Loading the Data

### Method 1: Command Line (Recommended)

From the `backend` directory:

```bash
python -m app.utils.load_destinations
```

This will:
- Read the `destinations.json` file from `backend/data/`
- Load each destination into Firestore's `destinations` collection
- Display success/failure status for each location

### Method 2: Python Script

```python
from app.services.data_loader import DataLoader

loader = DataLoader()
result = loader.load_destinations("path/to/destinations.json")
print(result)
```

## Firestore Collection Structure

After loading, your Firestore will have:

```
firestore/
└── destinations/
    ├── Montreal_Canada
    │   ├── city: "Montreal"
    │   ├── country: "Canada"
    │   ├── price: 300
    │   └── routes: { long, medium, short }
    ├── Toronto_Canada
    │   └── ...
    └── ... (other destinations)
```

Each document ID will be the key from your JSON (e.g., "Montreal_Canada").

## Using the Data

### For Shop Page (Buying Locations)
```python
destinations_ref = db.collection("destinations")
all_destinations = destinations_ref.stream()

for doc in all_destinations:
    city = doc.get('city')
    price = doc.get('price')
    # Display in shop
```

### For Mapbox Routes
```python
destination_doc = db.collection("destinations").document("Montreal_Canada").get()
long_route = destination_doc.get('routes.long')
start_coords = {
    'lat': long_route['start']['lat'],
    'lon': long_route['start']['lon']
}
end_coords = {
    'lat': long_route['end']['lat'],
    'lon': long_route['end']['lon']
}
# Use coordinates for Mapbox
```

## Data Validation

The data loader validates:
- ✓ Each destination has `city` and `country` fields
- ✓ JSON is properly formatted
- ✓ File exists and is readable

If errors occur, they will be reported with the failing destination ID.

## Next Steps

1. Create the `backend/data/` folder
2. Place your `destinations.json` file in it
3. Run the loader: `python -m app.utils.load_destinations`
4. Check Firebase Console to verify data is loaded
