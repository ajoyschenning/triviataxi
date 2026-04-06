//
//  UserManager.swift
//  triviataxi
//

import SwiftUI
import FirebaseAuth
import Foundation
internal import Combine

@MainActor
class UserManager: ObservableObject {
    
    @Published var coins: Int = 0
    @Published var ownedDestinations: [DestinationData] = []
    @Published var sessions: [TriviaSession] = []
    @Published var isProfileLoaded: Bool = false
    
    @Published var userProfile: UserProfile?
    
    func refreshSessions() async {
            do {
                guard let user = Auth.auth().currentUser else { return }
                let token = try await user.getIDToken()
                let uid = user.uid
                
                // Fetch only the sessions
                let fetchedSessions = try await NetworkService.shared.fetchUserSessions(userId: uid)
                
                // Update the published property to trigger a UI refresh
                self.sessions = fetchedSessions
                print("🔄 Sessions refreshed: \(fetchedSessions.count) trips found.")
            } catch {
                print("🚨 Failed to refresh sessions: \(error.localizedDescription)")
            }
        }
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // 🚀 Call this exactly ONCE when the app launches or the user logs in
    func loadUserProfile() async {
        
        guard !isProfileLoaded else { return } // Prevent duplicate fetches
        
        do {
            guard let user = Auth.auth().currentUser else { return }
            let token = try await user.getIDToken()
            
            // 1. Fetch the raw profile data
            let userProfile = try await NetworkService.shared.fetchUserProfile(token: token)
            
            // 2. Fetch the detailed city data
            var fetchedDestinations: [DestinationData] = []
            for destinationId in userProfile.owned {
                let destination = try await NetworkService.shared.fetchDestination(id: destinationId, token: token)
                fetchedDestinations.append(destination)
            }
            
            let fetchedSessions = try await NetworkService.shared.fetchUserSessions(userId: userProfile.firebaseUid)
            
            
            // 3. Save it all locally into RAM

                        // 🚀 ADD THESE TWO LINES:
                        print("DEBUG: Raw user profile: \(userProfile)")
                        print("DEBUG: Fetched coins: \(String(describing: userProfile.coins))")
                        
                        // ... existing code ...
                        
                        // 3. Save it all locally into RAM
            self.coins = userProfile.coins
            self.ownedDestinations = fetchedDestinations
            self.sessions = fetchedSessions
            self.isProfileLoaded = true
            self.userProfile = userProfile
            
            print("✅ User Profile locked into local memory.")
            
        } catch let decodingError as DecodingError {
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("🚨 MISSING KEY: \(key.stringValue) in \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("🚨 TYPE MISMATCH: Expected \(type) in \(context.debugDescription)")
            default:
                print("🚨 DECODING ERROR: \(decodingError)")
            }
        } catch {
            print("🚨 OTHER ERROR: \(error.localizedDescription)")
        }
    }
    func addCoins(amount: Int){
        self.coins+=amount
    }
    func updateUser(coins: Int,miles: Double){
        self.userProfile?.coins+=coins
        self.userProfile?.miles+=miles
        self.userProfile?.lifetimeGames+=1
    }
}
