"""FastAPI application entry point."""
# 1. ADD THESE IMPORTS
import firebase_admin
from firebase_admin import credentials

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.core.config import get_settings
from app.routes import users, sessions, leaderboard

cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)

settings = get_settings()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle: startup and shutdown."""
    # Startup
    print("Starting Trivia Taxi Backend...")
    
    # 2. ADD THIS FIREBASE INIT CODE
    # This checks if Firebase is already running to avoid "App already exists" crashes
    if not firebase_admin._apps:
        # On Cloud Run, this finds the credentials automatically.
        # Locally, it looks for your environment variables.
        firebase_admin.initialize_app(options={
            'projectId': 'trivia-taxi'
        })
        print("✅ Firebase Admin Initialized")
    
    yield
    # Shutdown
    print("Shutting down Trivia Taxi Backend...")



# Create FastAPI app
app = FastAPI(
    title=settings.api_title,
    version=settings.api_version,
    debug=settings.debug,
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: Restrict to actual iOS app domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(users.router)
app.include_router(sessions.router)
app.include_router(leaderboard.router)


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "app": settings.api_title,
        "version": settings.api_version,
        "status": "running"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.debug
    )
