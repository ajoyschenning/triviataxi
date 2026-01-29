"""Firestore database client and initialization."""
import firebase_admin
from firebase_admin import credentials, firestore
from app.core.config import get_settings
import json
import os


class FirestoreClient:
    """Singleton client for Firestore database interactions."""
    
    _instance = None
    _db = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(FirestoreClient, cls).__new__(cls)
        return cls._instance
    
    def __init__(self):
        """Initialize Firestore client if not already initialized."""
        if self._db is None:
            self._initialize_firebase()
    
    def _initialize_firebase(self):
        """Initialize Firebase app and Firestore database."""
        if not firebase_admin._apps:
            settings = get_settings()
            
            # Build credentials dictionary from environment
            creds_dict = {
                "type": "service_account",
                "project_id": settings.firebase_project_id,
                "private_key_id": settings.firebase_private_key_id,
                "private_key": settings.firebase_private_key.replace('\\n', '\n'),
                "client_email": settings.firebase_client_email,
                "client_id": settings.firebase_client_id,
                "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                "token_uri": "https://oauth2.googleapis.com/token",
                "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
            }
            
            # Initialize Firebase
            creds = credentials.Certificate(creds_dict)
            firebase_admin.initialize_app(creds)
        
        # Get Firestore client
        self._db = firestore.client()
    
    def get_db(self):
        """Get Firestore database instance."""
        return self._db
    
    # Collection helpers
    @property
    def users_collection(self):
        """Get users collection reference."""
        return self._db.collection("users")
    
    @property
    def sessions_collection(self):
        """Get game sessions collection reference."""
        return self._db.collection("game_sessions")
    
    @property
    def questions_collection(self):
        """Get questions collection reference."""
        return self._db.collection("questions")
    
    @property
    def leaderboard_collection(self):
        """Get leaderboard collection reference."""
        return self._db.collection("leaderboard")


def get_firestore_client() -> FirestoreClient:
    """Dependency injection for Firestore client."""
    return FirestoreClient()
