//
//  UserProfile.swift
//  triviataxi
//

import Foundation

struct UserProfile: Codable {
    let firebaseUid: String
    let username: String
    let email: String
    let avatarUrl: String?
    let coins: Double?
    let miles: Double?
    let owned: [String]?
    let lifetimeGames: Int?
    let winStreak: Int?
    let rank: Int?
    
    enum CodingKeys: String, CodingKey {
        case firebaseUid = "firebase_uid"
        case username
        case email
        case avatarUrl = "avatar_url"
        case coins
        case miles
        case owned
        case lifetimeGames = "lifetime_games"
        case winStreak = "win_streak"
        case rank
    }
}
