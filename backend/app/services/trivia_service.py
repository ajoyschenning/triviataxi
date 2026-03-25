"""Service for handling trivia question delivery and management."""
import httpx
import html
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
        params = {
            "amount": count,
            "type": "multiple"
        }
        if category:
            # Open Trivia DB uses numeric category IDs, but for simplicity, we'll skip category filtering for now
            pass
        if difficulty:
            params["difficulty"] = difficulty
        
        async with httpx.AsyncClient() as client:
            response = await client.get(TriviaService.OPEN_TRIVIA_BASE_URL, params=params)
            response.raise_for_status()
            data = response.json()
        
        if data.get("response_code") != 0:
            raise Exception(f"Open Trivia API error: {data.get('response_code')}")
        
        questions = []
        for result in data.get("results", []):
            # Decode HTML entities
            question = html.unescape(result["question"])
            correct_answer = html.unescape(result["correct_answer"])
            incorrect_answers = [html.unescape(ans) for ans in result["incorrect_answers"]]
            category = html.unescape(result["category"])
            
            questions.append({
                "question": question,
                "correct_answer": correct_answer,
                "incorrect_answers": incorrect_answers,
                "category": category,
                "difficulty": result["difficulty"]
            })
        
        return questions
    
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
        # The Open Trivia DB format is already normalized, but ensure all fields are present
        return {
            "question": raw_question.get("question", ""),
            "correct_answer": raw_question.get("correct_answer", ""),
            "incorrect_answers": raw_question.get("incorrect_answers", []),
            "category": raw_question.get("category", "General"),
            "difficulty": raw_question.get("difficulty", "medium")
        }
