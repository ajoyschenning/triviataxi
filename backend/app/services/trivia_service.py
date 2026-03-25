"""Service for handling trivia question delivery and management."""
import httpx
from typing import Dict, Any
import html
import asyncio
import time

class TriviaService:
    """Manages trivia question retrieval from external APIs."""
    
    OPEN_TRIVIA_BASE_URL = "https://opentdb.com/api.php"
    MIN_REQUEST_INTERVAL = 5.5  # OpenTrivia requires 5+ seconds between requests
    
    # Class-level variables to track rate limiting
    _last_request_time = 0.0
    _request_lock = asyncio.Lock()
    
    @classmethod
    async def _enforce_rate_limit(cls) -> None:
        """Enforce minimum time between API requests."""
        async with cls._request_lock:
            elapsed = time.time() - cls._last_request_time
            if elapsed < cls.MIN_REQUEST_INTERVAL:
                wait_time = cls.MIN_REQUEST_INTERVAL - elapsed
                await asyncio.sleep(wait_time)
            cls._last_request_time = time.time()
    
    @staticmethod
    async def get_question_from_open_trivia(
        category: str | None = None,
        difficulty: str | None = None,
        max_retries: int = 3
    ) -> Dict[str, Any]:
        """Fetch a single question from Open Trivia Database with rate limiting and retry logic.
        
        Args:
            category: Optional category ID for the question
            difficulty: Optional difficulty level (easy, medium, hard)
            max_retries: Maximum number of retries on 429 errors (default 3)
            
        Returns:
            Normalized question dictionary
            
        Raises:
            Exception: If the API call fails after all retries
        """
        params = {
            "amount": 1,
            "type": "multiple"  # Multiple choice questions
        }
        
        # Add optional parameters if provided
        if category:
            params["category"] = category
        if difficulty:
            params["difficulty"] = difficulty
        
        # Enforce rate limiting before making the request
        await TriviaService._enforce_rate_limit()
        
        retry_count = 0
        base_wait_time = 1.0
        
        while retry_count < max_retries:
            try:
                async with httpx.AsyncClient(timeout=15.0) as client:
                    response = await client.get(
                        TriviaService.OPEN_TRIVIA_BASE_URL,
                        params=params,
                    )
                    
                    # Handle 429 (Too Many Requests) with exponential backoff
                    if response.status_code == 429:
                        retry_count += 1
                        if retry_count >= max_retries:
                            raise Exception(
                                f"API rate limit exceeded after {max_retries} retries. "
                                "Please wait before making another request."
                            )
                        
                        # Exponential backoff: 1s, 2s, 4s
                        wait_time = base_wait_time * (2 ** (retry_count - 1))
                        print(f"Rate limited (429). Retry {retry_count}/{max_retries} after {wait_time}s...")
                        await asyncio.sleep(wait_time)
                        
                        # Reset rate limiter and try again
                        await TriviaService._enforce_rate_limit()
                        continue
                    
                    # Handle other HTTP errors
                    response.raise_for_status()
                    
                    data = response.json()
                    
                    # Check if the API returned results
                    if data.get("response_code") != 0 or not data.get("results"):
                        raise Exception(
                            f"OpenTrivia API error: response_code={data.get('response_code')}. "
                            "This may mean the API has no more questions for the given criteria."
                        )
                    
                    # Extract the first (and only) question
                    question = data["results"][0]
                    
                    # Normalize and return the question
                    return await TriviaService.normalize_question_format(question)
            
            except httpx.HTTPError as e:
                retry_count += 1
                if retry_count >= max_retries:
                    raise Exception(f"Failed to fetch from OpenTrivia API after {max_retries} attempts: {str(e)}")
                
                # Wait before retry with exponential backoff
                wait_time = base_wait_time * (2 ** (retry_count - 1))
                print(f"Request failed. Retry {retry_count}/{max_retries} after {wait_time}s...")
                await asyncio.sleep(wait_time)
    
    @staticmethod
    async def normalize_question_format(raw_question: Dict[str, Any]) -> Dict[str, Any]:
        """Normalize question format from OpenTrivia API.
        
        OpenTrivia returns HTML-encoded text, so we decode it for proper display.
        """
        return {
            "question": html.unescape(raw_question.get("question", "")),
            "correct_answer": html.unescape(raw_question.get("correct_answer", "")),
            "incorrect_answers": [
                html.unescape(ans) for ans in raw_question.get("incorrect_answers", [])
            ],
            "category": raw_question.get("category", "General"),
            "difficulty": raw_question.get("difficulty", "easy").lower()
        }
