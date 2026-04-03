//
//  Questions.swift
//  triviataxi
//

import Foundation

// MARK: - Open Trivia DB API Models

struct OpenTriviaResponse: Codable {
    let responseCode: Int
    let results: [OpenTriviaQuestion]
    
    enum CodingKeys: String, CodingKey {
        case responseCode = "response_code"
        case results
    }
}

struct OpenTriviaQuestion: Codable {
    let category: String
    let type: String
    let difficulty: String
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]
    
    enum CodingKeys: String, CodingKey {
        case category
        case type
        case difficulty
        case question
        case correctAnswer = "correct_answer"
        case incorrectAnswers = "incorrect_answers"
    }
}

// MARK: - HTML Entity Decoder

class HTMLEntityDecoder {
    private static let htmlEntities: [String: String] = [
        "&quot;": "\"",
        "&amp;": "&",
        "&apos;": "'",
        "&lt;": "<",
        "&gt;": ">",
        "&nbsp;": " ",
        "&#039;": "'",
        "&ndash;": "–",
        "&mdash;": "—",
        "&ldquo;": """,
        "&rdquo;": """,
        "&lsquo;": "'",
        "&rsquo;": "'",
        "&hellip;": "…",
        "&times;": "×",
        "&divide;": "÷",
        "&deg;": "°",
        "&plusmn;": "±",
    ]
    
    /// Decode HTML entities in a string (e.g., &quot; → ")
    static func decode(_ string: String) -> String {
        var decodedString = string
        
        // Replace named entities
        for (entity, character) in htmlEntities {
            decodedString = decodedString.replacingOccurrences(of: entity, with: character)
        }
        
        // Handle numeric entities (&#123; or &#x123;)
        // Decimal entities (&#65; = A)
        decodedString = decodedString.replacingOccurrences(
            of: "&#([0-9]+);",
            with: { match in
                if let codePoint = Int(match.replacingOccurrences(of: "&#|;", with: "", options: .regularExpression)),
                   let scalar = UnicodeScalar(codePoint) {
                    return String(Character(scalar))
                }
                return match.string
            },
            options: .regularExpression
        )
        
        // Hexadecimal entities (&#x41; = A)
        decodedString = decodedString.replacingOccurrences(
            of: "&#x([0-9a-fA-F]+);",
            with: { match in
                let hex = match.replacingOccurrences(of: "&#x|;", with: "", options: .regularExpression)
                if let codePoint = Int(hex, radix: 16),
                   let scalar = UnicodeScalar(codePoint) {
                    return String(Character(scalar))
                }
                return match.string
            },
            options: .regularExpression
        )
        
        return decodedString
    }
}

// MARK: - Trivia API Service

class TriviaAPIService {
    static let shared = TriviaAPIService()
    
    private let apiURL = "https://opentdb.com/api.php?amount=50&type=multiple"
    
    private init() {}
    
    /// Fetch a batch of 50 questions from Open Trivia DB
    /// Returns up to 50 Question objects, or falls back to sample questions on error
    func fetchQuestionsBatch(retryCount: Int = 1) async -> [Question] {
        do {
            guard let url = URL(string: apiURL) else {
                print("🚨 Invalid API URL")
                return getFallbackQuestions()
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("🚨 API returned status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                if retryCount > 0 {
                    // Retry once
                    return await fetchQuestionsBatch(retryCount: retryCount - 1)
                }
                return getFallbackQuestions()
            }
            
            let decoder = JSONDecoder()
            let triviaResponse = try decoder.decode(OpenTriviaResponse.self, from: data)
            
            // Check response code (0 = success)
            guard triviaResponse.responseCode == 0 else {
                print("🚨 Trivia API error code: \(triviaResponse.responseCode)")
                if retryCount > 0 {
                    return await fetchQuestionsBatch(retryCount: retryCount - 1)
                }
                return getFallbackQuestions()
            }
            
            // Map Open Trivia questions to our Question model
            let mappedQuestions = triviaResponse.results.enumerated().map { index, triviaQuestion in
                mapToQuestion(triviaQuestion, id: index)
            }
            
            print("✅ Successfully fetched \(mappedQuestions.count) questions from Open Trivia DB")
            return mappedQuestions
            
        } catch {
            print("🚨 Error fetching questions: \(error.localizedDescription)")
            if retryCount > 0 {
                return await fetchQuestionsBatch(retryCount: retryCount - 1)
            }
            return getFallbackQuestions()
        }
    }
    
    /// Map Open Trivia Question to our Question model
    private func mapToQuestion(_ triviaQuestion: OpenTriviaQuestion, id: Int) -> Question {
        let decodedQuestion = HTMLEntityDecoder.decode(triviaQuestion.question)
        let decodedCorrectAnswer = HTMLEntityDecoder.decode(triviaQuestion.correctAnswer)
        let decodedIncorrectAnswers = triviaQuestion.incorrectAnswers.map {
            HTMLEntityDecoder.decode($0)
        }
        
        // Map difficulty: "easy" -> "Easy", "medium" -> "Medium", "hard" -> "Hard"
        let normalizedDifficulty = triviaQuestion.difficulty.prefix(1).uppercased() +
                                  triviaQuestion.difficulty.dropFirst().lowercased()
        
        // Determine earning value based on difficulty
        let earningValue: Int
        switch triviaQuestion.difficulty.lowercased() {
        case "easy":
            earningValue = 5
        case "medium":
            earningValue = 10
        case "hard":
            earningValue = 15
        default:
            earningValue = 10
        }
        
        return Question(
            questionId: "q_\(id)_\(UUID().uuidString.prefix(8))",
            text: decodedQuestion,
            category: triviaQuestion.category,
            difficulty: normalizedDifficulty,
            earningValue: earningValue,
            correctAnswer: decodedCorrectAnswer,
            incorrectAnswers: decodedIncorrectAnswers
        )
    }
    
    /// Get fallback hardcoded questions if API fails
    private func getFallbackQuestions() -> [Question] {
        print("⚠️ Using fallback hardcoded questions")
        return [
            Question(
                questionId: "1",
                text: "What is the capital of France?",
                category: "Geography",
                difficulty: "Easy",
                earningValue: 5,
                correctAnswer: "Paris",
                incorrectAnswers: ["London", "Berlin", "Madrid"]
            ),
            Question(
                questionId: "2",
                text: "Which planet is known as the Red Planet?",
                category: "Science",
                difficulty: "Easy",
                earningValue: 5,
                correctAnswer: "Mars",
                incorrectAnswers: ["Venus", "Jupiter", "Saturn"]
            ),
            Question(
                questionId: "3",
                text: "What is the largest ocean on Earth?",
                category: "Geography",
                difficulty: "Easy",
                earningValue: 5,
                correctAnswer: "Pacific Ocean",
                incorrectAnswers: ["Atlantic Ocean", "Indian Ocean", "Arctic Ocean"]
            ),
            Question(
                questionId: "4",
                text: "Who wrote 'Romeo and Juliet'?",
                category: "Literature",
                difficulty: "Easy",
                earningValue: 5,
                correctAnswer: "William Shakespeare",
                incorrectAnswers: ["Jane Austen", "Charles Dickens", "Mark Twain"]
            ),
            Question(
                questionId: "5",
                text: "What is the chemical symbol for gold?",
                category: "Science",
                difficulty: "Easy",
                earningValue: 5,
                correctAnswer: "Au",
                incorrectAnswers: ["Ag", "Fe", "Cu"]
            ),
            Question(
                questionId: "6",
                text: "In what year did the Titanic sink?",
                category: "History",
                difficulty: "Medium",
                earningValue: 10,
                correctAnswer: "1912",
                incorrectAnswers: ["1905", "1920", "1898"]
            ),
            Question(
                questionId: "7",
                text: "What is the smallest prime number?",
                category: "Mathematics",
                difficulty: "Easy",
                earningValue: 5,
                correctAnswer: "2",
                incorrectAnswers: ["1", "3", "0"]
            ),
            Question(
                questionId: "8",
                text: "Which country is home to the Eiffel Tower?",
                category: "Geography",
                difficulty: "Easy",
                earningValue: 5,
                correctAnswer: "France",
                incorrectAnswers: ["Italy", "Germany", "Spain"]
            ),
            Question(
                questionId: "9",
                text: "What is the capital of Japan?",
                category: "Geography",
                difficulty: "Easy",
                earningValue: 5,
                correctAnswer: "Tokyo",
                incorrectAnswers: ["Osaka", "Kyoto", "Hiroshima"]
            ),
            Question(
                questionId: "10",
                text: "How many continents are there?",
                category: "Geography",
                difficulty: "Easy",
                earningValue: 5,
                correctAnswer: "7",
                incorrectAnswers: ["5", "6", "8"]
            ),
        ]
    }
}

