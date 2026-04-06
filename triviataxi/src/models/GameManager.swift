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
    let earningValue: Int
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
    
    @Published var questions: [Question] = []
    @Published var currentIndex: Int = 0
    @Published var currentEarnings: Int = 0
    @Published var strikes: Int = 0
    @Published var hintsEarningsSpent: Int = 0
    @Published var isGameOver: Bool = false
    @Published var milesTravelled: Double = 0.0
    @Published var timeElapsed: Int = 0 // in seconds
    
    private var timeTimer: Timer? = nil
    
    let maxStrikes: Int = 3
    
    // Safety property to always grab the active question
    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    @Published var routeId: String = ""
    
    
    /// Call this once when Mapbox starts the route
    func startSession(routeId: String) {
            
            self.routeId = routeId
            self.currentIndex = 0
            self.currentEarnings = 0
            self.strikes = 0
            self.hintsEarningsSpent = 0
            self.isGameOver = false
            self.milesTravelled = 0.0
            self.timeElapsed = 0
            
            // Start the timer
            startTimeTimer()
        }
    

    
    /// Locks the local game state and triggers the final background upload
    func endGameLocally(userManager: UserManager) {
        self.isGameOver = true
        stopTimeTimer()
        
        Task {
            await uploadFinalResults(userManager: userManager)
        }
    }
    
    /// Forces the session to end early if the user exits the map
        func quitSessionEarly(userManager: UserManager) {
            guard !isGameOver else { return } // Prevent double-uploads if they already finished
            
            self.isGameOver = true
            stopTimeTimer()
            
            Task {
                await uploadFinalResults(userManager: userManager)
                print("🛑 Trip aborted. Uploading partial earnings...")
                
            }
        }
    
    /// The ONLY time the game talks to the API after starting
    private func uploadFinalResults(userManager: UserManager) async {
        
        do {
            let res = try await NetworkService.shared.submitGameResults(
                userId: userManager.currentUserId!,
                routeId: self.routeId,
                totalEarnings: self.currentEarnings,
                strikes: self.strikes,
                questionsAnswered: self.currentIndex+1)
            print("✅ Final Game Data uploaded successfully! SessionID: \(res.sessionId) \(self.currentEarnings)")

            userManager.addCoins(amount: self.currentEarnings)
            
        } catch {
            print("🚨 Failed to upload game results: \(error.localizedDescription)")
        }
    }
    
    func addEarnings(earningValue: Int) {
       currentEarnings += earningValue
    }
    
    func spendEarningsOnHint(amount: Int) {
        hintsEarningsSpent += amount
    }
    
    func incrementStrikes() {
        strikes += 1
    }
    
    func updateMilesTravelled(_ miles: Double) {
        milesTravelled = miles
    }
    
    private func startTimeTimer() {
        timeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timeElapsed += 1
        }
    }
    
    private func stopTimeTimer() {
        timeTimer?.invalidate()
        timeTimer = nil
    }
}

