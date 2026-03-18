"""Service for handling trivia question delivery and management."""
import httpx
import html
from typing import List, Dict, Any

class TriviaService:
    """Manages trivia question retrieval from external APIs."""
    
    # Trivia DB API endpoint - returns one question per request
    OPEN_TRIVIA_BASE_URL = "https://opentdb.com/api.php"
    
    @staticmethod
    def _clean_text(text: str) -> str:
        """Clean and format text by decoding HTML entities and normalizing whitespace.
        
        Handles:
        - HTML entity decoding (&quot; -> ", &amp; -> &, etc.)
        - Extra whitespace normalization
        - Proper string trimming
        """
        # Decode HTML entities
        decoded = html.unescape(text)
        # Normalize whitespace (remove extra spaces, tabs, newlines)
        cleaned = " ".join(decoded.split())
        return cleaned
    
    @staticmethod
    async def get_questions_from_open_trivia(
        category: str | None = None,
        difficulty: str | None = None
    ) -> List[Dict[str, Any]]:
        """Fetch one question from Open Trivia Database.
        
        Fetches a single question at a time. Call this method repeatedly as needed
        based on route duration and user performance.
        """
        params = {
            "amount": 1,
            "type": "multiple"
        }
        if category:
            params["category"] = category
        if difficulty:
            params["difficulty"] = difficulty
        
        async with httpx.AsyncClient() as client:
            response = await client.get(TriviaService.OPEN_TRIVIA_BASE_URL, params=params)
            response.raise_for_status()
            data = response.json()
        
        # Check for API errors
        if data.get("response_code") != 0:
            raise Exception(f"Open Trivia API error: {data.get('response_code')}")
        
        # Extract and process the single question in the response
        questions = []
        if data.get("results"):
            result = data["results"][0]
            # Clean and format all text fields
            question = TriviaService._clean_text(result["question"])
            correct_answer = TriviaService._clean_text(result["correct_answer"])
            incorrect_answers = [TriviaService._clean_text(ans) for ans in result["incorrect_answers"]]
            category_name = TriviaService._clean_text(result["category"])
            
            questions.append({
                "question": question,
                "correct_answer": correct_answer,
                "incorrect_answers": incorrect_answers,
                "category": category_name,
                "difficulty": result["difficulty"]
            })
        
        return questions
    
    @staticmethod
    async def get_questions_from_trivia_api(
        category: str | None = None,
        difficulty: str | None = None
    ) -> List[Dict[str, Any]]:
        """Fetch one question from the Trivia API."""
        return await TriviaService.get_questions_from_open_trivia(category, difficulty)
    
    @staticmethod
    async def normalize_question_format(raw_question: Dict[str, Any]) -> Dict[str, Any]:
        """Normalize question format across different APIs.
        
        Ensures all text fields are cleaned of HTML entities and properly formatted.
        """
        return {
            "question": TriviaService._clean_text(raw_question.get("question", "")),
            "correct_answer": TriviaService._clean_text(raw_question.get("correct_answer", "")),
            "incorrect_answers": [TriviaService._clean_text(ans) for ans in raw_question.get("incorrect_answers", [])],
            "category": TriviaService._clean_text(raw_question.get("category", "General")),
            "difficulty": raw_question.get("difficulty", "medium")
        }
