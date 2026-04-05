//
//  UserProfile.swift
//  triviataxi
//

import Foundation

struct UserProfile: Codable, Identifiable {
    var id: String { firebaseUid }
    
    let firebaseUid: String
    var username: String
    let email: String
    var avatarUrl: String?
    
    var coins: Int = 0
    var miles: Double = 0.0
    
    var owned: [String] = []
    var sessions: [String] = []
    var lifetimeGames: Int = 0
    var winStreak: Int = 0
    
    var rank: Int?

    enum CodingKeys: String, CodingKey {
        case firebaseUid = "firebase_uid"
        case username
        case email
        case avatarUrl = "avatar_url"
        case coins
        case miles
        case owned
        case sessions
        case lifetimeGames = "lifetime_games"
        case winStreak = "win_streak"
        case rank
    }
}
