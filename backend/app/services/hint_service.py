"""Service for AI-powered hint generation."""
import openai


class HintService:
    """Generates contextual, non-spoiler hints using OpenAI API."""
    
    @staticmethod
    async def generate_hint(question: str, correct_answer: str) -> str:
        """Generate a non-spoiler hint for a trivia question."""
        # TODO: Implement OpenAI hint generation with safety guardrails
        pass
    
    @staticmethod
    def get_cached_hint(question_id: str) -> str | None:
        """Retrieve cached hint from Redis if available."""
        # TODO: Implement Redis caching for hints
        pass
    
    @staticmethod
    async def cache_hint(question_id: str, hint: str) -> None:
        """Cache generated hint in Redis."""
        # TODO: Implement hint caching
        pass
