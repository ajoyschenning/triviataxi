//
//  TriviaSession.swift
//  triviataxi
//


struct TriviaSession: Codable, Identifiable {
    let id: String
    let date: String
    let miles: Double
    let coins: Int
    let wasPerfect: Bool
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case date, miles, coins, timestamp
        case wasPerfect = "was_perfect"
    }
}
