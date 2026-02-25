import Foundation

// 1. The model for starting a new trip (POST /sessions)
struct SessionResponse: Codable {
    let sessionId: String
    
    // Add any other fields your create_session python route actually returns,
    // like journey_id or total_distance. But sessionId is the only strictly required one for now.
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
    }
}

// 2. The model for answering a question (POST /{session_id}/answer)
struct AnswerResponse: Codable {
    let isCorrect: Bool
    let earnedAmount: Double
    let currentStrikes: Int
    let currentEarnings: Double
    let progressPercent: Double
    let sessionEnded: Bool
    let nextQuestion: Question?
    
    enum CodingKeys: String, CodingKey {
        case isCorrect = "is_correct"
        case earnedAmount = "earned_amount"
        case currentStrikes = "current_strikes"
        case currentEarnings = "current_earnings"
        case progressPercent = "progress_percent"
        case sessionEnded = "session_ended"
        case nextQuestion = "next_question"
    }
}

// 3. The universal Question model
struct Question: Codable, Identifiable {
    var id: String { questionId }
    let questionId: String
    let text: String
    let category: String
    let difficulty: String
    let earningValue: Double
    let incorrectAnswers: [String]
    
    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case text = "question_text" // Ensure this matches your Python dictionary key!
        case category
        case difficulty
        case earningValue = "earning_value"
        case incorrectAnswers = "incorrect_answers"
    }
}
