//
//  Questions.swift
//  triviataxi
//

import Foundation
import FirebaseAuth

// MARK: - String Extension for HTML Entity Decoding
extension String {
    /// Decodes HTML entities in the string (e.g., &amp; -> &, &quot; -> ", etc.)
    var decodedHTMLEntities: String {
        var result = self
        
        // Common HTML entities
        let entities: [String: String] = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'",
            "&nbsp;": " ",
            "&#039;": "'",
            "&#8217;": "'",
            "&#8220;": """,
            "&#8221;": """,
            "&#8211;": "–",
            "&#8212;": "—"
        ]
        
        for (entity, character) in entities {
            result = result.replacingOccurrences(of: entity, with: character)
        }
        
        return result
    }
}

// MARK: - Question Model (for UI)
struct Question: Codable {
    let questionId: String
    let text: String
    let category: String
    let difficulty: String
    let earningValue: Double
    let correctAnswer: String
    let incorrectAnswers: [String]
    
    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case text
        case category
        case difficulty
        case earningValue = "earning_value"
        case correctAnswer = "correct_answer"
        case incorrectAnswers = "incorrect_answers"
    }
    
    /// Returns a question with all text fields decoded from HTML entities
    func withDecodedText() -> Question {
        Question(
            questionId: questionId,
            text: text.decodedHTMLEntities,
            category: category.decodedHTMLEntities,
            difficulty: difficulty.decodedHTMLEntities,
            earningValue: earningValue,
            correctAnswer: correctAnswer.decodedHTMLEntities,
            incorrectAnswers: incorrectAnswers.map { $0.decodedHTMLEntities }
        )
    }
}

// MARK: - Question Loader
class QuestionLoader: NSObject, ObservableObject {
    @Published var questions: [Question] = []
    @Published var isLoading = false
    @Published var error: NetworkError? = nil
    
    private let networkService = NetworkService.shared
    
    /// Fetch trivia questions for a game session
    /// - Parameters:
    ///   - sessionId: The game session ID
    /// - Returns: An array of Question objects
    func fetchQuestionsForSession(_ sessionId: String) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            guard let token = try await Auth.auth().currentUser?.getIDToken() else {
                throw NetworkError.unauthorized
            }
            
            let question = try await networkService.fetchQuestion(
                sessionId: sessionId,
                token: token
            )
            
            // Convert NetworkService.Question to UI Question with decoded text
            let uiQuestion = Question(
                questionId: question.questionId,
                text: question.text,
                category: question.category,
                difficulty: question.difficulty,
                earningValue: question.earningValue,
                correctAnswer: question.correctAnswer,
                incorrectAnswers: question.incorrectAnswers
            ).withDecodedText()
            
            await MainActor.run {
                self.questions = [uiQuestion]
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                if let networkError = error as? NetworkError {
                    self.error = networkError
                } else {
                    self.error = NetworkError.decodingError
                }
                self.isLoading = false
            }
            print("🚨 Error fetching questions: \(error)")
        }
    }
    
    /// Fetch multiple questions for continuous gameplay
    /// - Parameters:
    ///   - sessionId: The game session ID
    ///   - count: Number of questions to fetch
    /// - Returns: An array of Question objects
    func fetchMultipleQuestions(_ sessionId: String, count: Int = 10) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        var fetchedQuestions: [Question] = []
        
        do {
            guard let token = try await Auth.auth().currentUser?.getIDToken() else {
                throw NetworkError.unauthorized
            }
            
            // Fetch questions one at a time (as the backend trivia service returns one at a time)
            for _ in 0..<count {
                let question = try await networkService.fetchQuestion(
                    sessionId: sessionId,
                    token: token
                )
                
                let uiQuestion = Question(
                    questionId: question.questionId,
                    text: question.text,
                    category: question.category,
                    difficulty: question.difficulty,
                    earningValue: question.earningValue,
                    correctAnswer: question.correctAnswer,
                    incorrectAnswers: question.incorrectAnswers
                ).withDecodedText()
                
                fetchedQuestions.append(uiQuestion)
            }
            
            await MainActor.run {
                self.questions = fetchedQuestions
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                if let networkError = error as? NetworkError {
                    self.error = networkError
                } else {
                    self.error = NetworkError.decodingError
                }
                self.isLoading = false
            }
            print("🚨 Error fetching multiple questions: \(error)")
        }
    }
}