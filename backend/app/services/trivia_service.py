"""Service for handling trivia question delivery and management."""
import httpx
from typing import List, Dict, Any

#TODO: This is hard coded for testing. 
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
        # Hardcoded questions for testing
        return [
            {
                "question": "What is the capital of France?",
                "correct_answer": "Paris",
                "incorrect_answers": ["London", "Berlin", "Madrid"],
                "category": "Geography",
                "difficulty": "easy"
            },
            {
                "question": "Who wrote 'Hamlet'?",
                "correct_answer": "William Shakespeare",
                "incorrect_answers": ["Charles Dickens", "Jane Austen", "Mark Twain"],
                "category": "Literature",
                "difficulty": "medium"
            },
            {
                "question": "What is the chemical symbol for water?",
                "correct_answer": "H2O",
                "incorrect_answers": ["CO2", "NaCl", "O2"],
                "category": "Science",
                "difficulty": "easy"
            },
            {
                "question": "Which planet is known as the Red Planet?",
                "correct_answer": "Mars",
                "incorrect_answers": ["Venus", "Jupiter", "Saturn"],
                "category": "Science",
                "difficulty": "easy"
            },
            {
                "question": "In which year did the Titanic sink?",
                "correct_answer": "1912",
                "incorrect_answers": ["1905", "1918", "1925"],
                "category": "History",
                "difficulty": "medium"
            }
        ][:count]
    
    @staticmethod
    async def get_questions_from_trivia_api(
        count: int = 5,
        category: str | None = None,
        difficulty: str | None = None
    ) -> List[Dict[str, Any]]:
        """Fetch questions from The Trivia API."""
        # Hardcoded questions for testing
        return await TriviaService.get_questions_from_open_trivia(count, category, difficulty)
    
    @staticmethod
    async def normalize_question_format(raw_question: Dict[str, Any]) -> Dict[str, Any]:
        """Normalize question format across different APIs."""
        # Simple passthrough for hardcoded questions
        return raw_question
