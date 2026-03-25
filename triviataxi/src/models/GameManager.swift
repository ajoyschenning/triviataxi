// ORIGINAL FILE: triviataxi/src/models/GameManager.swift

// //
// //  GameManager.swift
// //  triviataxi
// //

// import SwiftUI
// import FirebaseAuth
// import Foundation
// internal import Combine


// // MARK: - 1. Data Models

// // The payload sent back to Python when the game is completely over
// struct GameCompletionRequest: Codable {
//     let sessionId: String
    
//     enum CodingKeys: String, CodingKey {
//             case sessionId = "session_id"
//         }
// }


// struct Question: Codable, Identifiable {
//     var id: String { questionId }
//     let questionId: String
//     let text: String
//     let category: String
//     let difficulty: String
//     let earningValue: Int
//     let correctAnswer: String
//     let incorrectAnswers: [String]

//     enum CodingKeys: String, CodingKey {
//         case questionId = "question_id"
//         case text = "question_text"
//         case category
//         case difficulty
//         case earningValue = "earning_value"
//         case correctAnswer = "correct_answer"
//         case incorrectAnswers = "incorrect_answers"
//     }
// }


// // MARK: - 2. The Local Game Brain

// @MainActor
// class GameManager: ObservableObject {
    
//     @Published var questions: [Question] = []
//     @Published var currentIndex: Int = 0
//     @Published var currentEarnings: Int = 0
//     @Published var strikes: Int = 0
//     @Published var isGameOver: Bool = false
    
    
//     // Safety property to always grab the active question
//     var currentQuestion: Question? {
//         guard currentIndex < questions.count else { return nil }
//         return questions[currentIndex]
//     }
    
//     @Published var routeId: String = ""
//     private let maxStrikes: Int = 3
    
//     func setRouteId(routeId: String) {
//         // Defer the publish to the next runloop tick to avoid publishing during view updates
//         Task { @MainActor in
//             if self.routeId != routeId {
//                 self.routeId = routeId
//             }
//         }
//     }
    
//     /// Call this once when Mapbox starts the route
//     func startSession(routeId: String, fetchedQuestions: [Question]) {
//         // Defer batched publishes to avoid triggering SwiftUI's "Publishing changes from within view updates" warning
//         Task { @MainActor in
//             self.routeId = routeId
//             self.questions = fetchedQuestions
//             self.currentIndex = 0
//             self.currentEarnings = 0
//             self.strikes = 0
//             self.isGameOver = false
//         }
//     }
    
//     /// Grades the user's tap instantly with zero API latency
//     func submitAnswer(_ selectedAnswer: String, userManager: UserManager) {
//         guard let question = currentQuestion, !isGameOver else { return }
        
//         let isCorrect = (selectedAnswer == question.correctAnswer)
        
//         if isCorrect {
//             currentEarnings += question.earningValue
//         } else {
//             strikes += 1
//         }
        
//         // Check for game over conditions (Out of questions OR 3 strikes)
//         if strikes >= maxStrikes || currentIndex + 1 >= questions.count {
//             endGameLocally(userManager: userManager)
//         } else {
//             // Move to the next question
//             currentIndex += 1
//         }
//     }
    
//     /// Locks the local game state and triggers the final background upload
//     private func endGameLocally(userManager: UserManager) {
//         self.isGameOver = true
        
//         Task {
//             await uploadFinalResults(userManager: userManager)
//         }
//     }
    
//     /// Forces the session to end early if the user exits the map
//         func quitSessionEarly(userManager: UserManager) {
//             guard !isGameOver else { return } // Prevent double-uploads if they already finished
            
//             self.isGameOver = true
            
//             Task {
//                 await uploadFinalResults(userManager: userManager)
//                 print("🛑 Trip aborted. Uploading partial earnings...")
//             }
//         }
    
//     /// The ONLY time the game talks to the API after starting
//     private func uploadFinalResults(userManager: UserManager) async {
        
//         do {
//             // Example Network Call - Replace with your actual NetworkService function
//             let res = try await NetworkService.shared.submitGameResults(
//                 userId: userManager.currentUserId!,
//                 routeId: self.routeId,
//                 totalEarnings: self.currentEarnings,
//                 strikes: self.strikes,
//                 questionsAnswered: self.currentIndex+1)
//             print("✅ Final Game Data uploaded successfully! SessionID: \(res.sessionId)")

//             await userManager.loadUserProfile()
            
//         } catch {
//             print("🚨 Failed to upload game results: \(error.localizedDescription)")
//         }
//     }
// }




//
//  GameManager.swift
//  triviataxi
//

import SwiftUI
import FirebaseAuth
import Foundation
internal import Combine


// MARK: - 1. Data Models

// The payload sent back to Python when the game is completely over
struct GameCompletionRequest: Codable {
    let sessionId: String
    
    enum CodingKeys: String, CodingKey {
            case sessionId = "session_id"
        }
}


struct Question: Codable, Identifiable {
    var id: String { questionId }
    let questionId: String
    let text: String
    let category: String
    let difficulty: String
    let earningValue: Int?  // Optional as it's calculated on the client side
    let correctAnswer: String
    let incorrectAnswers: [String]

    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case text = "question_text"
        case category
        case difficulty
        case earningValue = "earning_value"
        case correctAnswer = "correct_answer"
        case incorrectAnswers = "incorrect_answers"
    }
}


// MARK: - 2. The Local Game Brain

@MainActor
class GameManager: ObservableObject {
    
    @Published var currentEarnings: Int = 0
    @Published var strikes: Int = 0
    @Published var isGameOver: Bool = false
    @Published var sessionId: String = ""
    @Published var routeId: String = ""
    
    private let maxStrikes: Int = 3
    private var currentUserManager: UserManager?
    
    func setRouteId(routeId: String) {
        Task { @MainActor in
            if self.routeId != routeId {
                self.routeId = routeId
            }
        }
    }
    
    /// Initialize a new game session
    func startSession(sessionId: String, routeId: String) {
        Task { @MainActor in
            self.sessionId = sessionId
            self.routeId = routeId
            self.currentEarnings = 0
            self.strikes = 0
            self.isGameOver = false
        }
    }
    
    /// Submit a single answer and update game state
    /// - Parameters:
    ///   - selectedAnswer: The answer the user selected
    ///   - correctAnswer: The correct answer from the question
    ///   - earningValue: Points earned for correct answer (defaults to 10)
    ///   - userManager: Reference to user manager for final upload
    func submitAnswer(
        _ selectedAnswer: String,
        correctAnswer: String,
        earningValue: Int? = 10,
        userManager: UserManager
    ) {
        guard !isGameOver else { return }
        
        let isCorrect = (selectedAnswer == correctAnswer)
        
        if isCorrect {
            // Use earningValue if available, default to 10
            let points = earningValue ?? 10
            currentEarnings += points
        } else {
            strikes += 1
        }
        
        // Check for game over condition (3 strikes)
        if strikes >= maxStrikes {
            endGameLocally(userManager: userManager)
        }
    }
    
    /// Locks the local game state and triggers the final background upload
    private func endGameLocally(userManager: UserManager) {
        self.isGameOver = true
        self.currentUserManager = userManager
        
        Task {
            await uploadFinalResults(userManager: userManager)
        }
    }
    
    /// Forces the session to end early if the user exits the map
    func quitSessionEarly(userManager: UserManager) {
        guard !isGameOver else { return } // Prevent double-uploads if already finished
        
        self.isGameOver = true
        
        Task {
            await uploadFinalResults(userManager: userManager)
            print("🛑 Trip aborted. Uploading partial earnings...")
        }
    }
    
    /// The ONLY time the game talks to the API after starting
    private func uploadFinalResults(userManager: UserManager) async {
        do {
            let res = try await NetworkService.shared.submitGameResults(
                userId: userManager.currentUserId ?? "unknown",
                routeId: self.routeId,
                totalEarnings: self.currentEarnings,
                strikes: self.strikes,
                questionsAnswered: 0  // Will be tracked on backend via question submissions
            )
            print("✅ Final Game Data uploaded successfully! SessionID: \(res.sessionId)")
            
            await userManager.loadUserProfile()
            
        } catch {
            print("🚨 Failed to upload game results: \(error.localizedDescription)")
        }
    }
}

