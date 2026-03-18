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
    @Published var isProfileLoaded: Bool = false
    
    // 🚀 FIX: Added the missing property so the ShopViewModel can safely read it!
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
            for destinationId in userProfile.owned ?? [] {
                let destination = try await NetworkService.shared.fetchDestination(id: destinationId, token: token)
                fetchedDestinations.append(destination)
            }
            
            // 3. Save it all locally into RAM

                        // 🚀 ADD THESE TWO LINES:
                        print("DEBUG: Raw user profile: \(userProfile)")
                        print("DEBUG: Fetched coins: \(String(describing: userProfile.coins))")
                        
                        // ... existing code ...
                        
                        // 3. Save it all locally into RAM
            self.coins = Int(userProfile.coins ?? 0)
            self.ownedDestinations = fetchedDestinations
            self.isProfileLoaded = true
            
            print("✅ User Profile locked into local memory.")
            
        } catch {
            print("🚨 Failed to load user profile: \(error.localizedDescription)")
        }
    }
    
    func deductCoins(amount: Int) {
        self.coins -= amount
    }
}
