# Trivia Taxi Backend

FastAPI-based backend for the Trivia Taxi mobile game.

## Project Structure

```
backend/
├── app/
│   ├── core/              # Configuration and core utilities
│   ├── models/            # SQLAlchemy database models
│   ├── routes/            # FastAPI route handlers
│   ├── services/          # Business logic services
│   └── __init__.py
├── main.py               # FastAPI application entry point
├── requirements.txt      # Python dependencies
├── .env.example         # Environment variables template
└── README.md
```

## API Endpoints

### Users
- `POST /users/me` - Create user profile on first login
- `GET /users/me` - Get current user profile and stats
- `PUT /users/me` - Update user profile

### Game Sessions
- `POST /sessions` - Create a new trivia trip session
- `GET /sessions/{session_id}` - Get session state
- `POST /sessions/{session_id}/answer` - Submit answer
- `POST /sessions/{session_id}/skip` - Skip question
- `POST /sessions/{session_id}/end` - End session early
- `GET /sessions/{session_id}/question` - Get current question
- `POST /sessions/{session_id}/hint` - Generate AI hint

### Leaderboards
- `GET /leaderboards/global` - Get global leaderboard
- `GET /leaderboards/friends` - Get friends leaderboard
- `GET /leaderboards/me/history` - Get personal history

### Health
- `GET /health` - Health check endpoint
- `GET /` - Root endpoint

## Next Steps

1. Set up Python virtual environment
2. Install dependencies
3. Configure environment variables
4. Initialize database
5. Implement service methods
6. Add database migrations
7. Integrate Firebase Authentication
8. Test API endpoints
