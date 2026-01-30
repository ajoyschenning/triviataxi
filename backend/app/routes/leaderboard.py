"""Leaderboard API endpoints."""
from fastapi import APIRouter
from pydantic import BaseModel
from typing import List

router = APIRouter(prefix="/leaderboards", tags=["leaderboards"])


class LeaderboardEntry(BaseModel):
    """Leaderboard entry model."""
    rank: int
    username: str
    total_earnings: float
    lifetime_games: int


class LeaderboardResponse(BaseModel):
    """Leaderboard response model."""
    entries: List[LeaderboardEntry]
    user_rank: LeaderboardEntry | None
    timeframe: str


@router.get("/global", response_model=LeaderboardResponse)
async def get_global_leaderboard(timeframe: str = "all_time", limit: int = 100):
    """Get global leaderboard ranked by lifetime earnings."""
    # TODO: Implement global leaderboard retrieval
    return {}


@router.get("/friends", response_model=LeaderboardResponse)
async def get_friends_leaderboard(timeframe: str = "weekly"):
    """Get friends leaderboard (requires friends feature)."""
    # TODO: Implement friends leaderboard
    return {}


@router.get("/me/history")
async def get_personal_history():
    """Get personal performance trends."""
    # TODO: Implement personal history retrieval
    return {}
