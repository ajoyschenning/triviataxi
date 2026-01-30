"""Service for handling trivia question delivery and management."""
import httpx
from typing import List, Dict, Any


class TriviaService:
    """Manages trivia question retrieval from external APIs."""
    
    OPEN_TRIVIA_BASE_URL = "https://opentdb.com/api.php"
    THE_TRIVIA_API_BASE_URL = "https://the-trivia-api.com/v2"
    
    @staticmethod
    async def get_questions_from_open_trivia(
        count: int = 5,
        category: str | None = None,
        difficulty: str | None = None
    ) -> List[Dict[str, Any]]:
        """Fetch questions from Open Trivia Database."""
        # TODO: Implement Open Trivia Database integration
        pass
    
    @staticmethod
    async def get_questions_from_trivia_api(
        count: int = 5,
        category: str | None = None,
        difficulty: str | None = None
    ) -> List[Dict[str, Any]]:
        """Fetch questions from The Trivia API."""
        # TODO: Implement The Trivia API integration
        pass
    
    @staticmethod
    async def normalize_question_format(raw_question: Dict[str, Any]) -> Dict[str, Any]:
        """Normalize question format across different APIs."""
        # TODO: Implement question normalization
        pass
