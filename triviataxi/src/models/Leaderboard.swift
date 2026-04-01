//
//  Leaderboard.swift
//  triviataxi
//
//

import Foundation

/// Represents a single entry on the distance-based leaderboard.
struct LeaderboardEntry: Codable, Identifiable {
    
    // 🚀 Uses entryId as the unique identifier for SwiftUI Lists
    var id: String { entryId }
    
    let entryId: String
    let firebaseUid: String
    let username: String
    
    // 📈 Hero Metric: Use Double to match Python's float precision
    let milesTraveled: Double
    let lifetimeGames: Int
    let rank: Int
    
    // ⏳ Type-safe timeframe
    let timeframe: LeaderboardTimeframe
    
    // 📅 Maps to Python's ISO8601 datetime string
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case entryId = "entry_id"
        case firebaseUid = "firebase_uid"
        case username
        case milesTraveled = "miles_traveled"
        case lifetimeGames = "lifetime_games"
        case rank
        case timeframe
        case updatedAt = "updated_at"
    }
}

/// Supported timeframes for ranking.
enum LeaderboardTimeframe: String, Codable {
    case weekly = "weekly"
    case monthly = "monthly"
    case allTime = "all_time"
}
