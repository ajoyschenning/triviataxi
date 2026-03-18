//
//  NetworkService.swift
//  triviataxi
//

import Foundation
import FirebaseAuth

// Helper to decode dynamic JSON values
struct AnyCodable: Codable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let dictVal = try? container.decode([String: AnyCodable].self)
        {
            value = dictVal.mapValues { $0.value }
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            value = arrayVal.map { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intVal = value as? Int {
            try container.encode(intVal)
        } else if let doubleVal = value as? Double {
            try container.encode(doubleVal)
        } else if let stringVal = value as? String {
            try container.encode(stringVal)
        } else if let boolVal = value as? Bool {
            try container.encode(boolVal)
        } else {
            try container.encodeNil()
        }
    }
}

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case unauthorized
    case serverError(Int)
}

class NetworkService {
    static let shared = NetworkService()
    private let baseURL = "https://trivia-taxi-api-423193744278.us-central1.run.app/"
    


    
    func submitGameResults(
        userId: String,
        routeId: String,
        totalEarnings: Int,
        strikes: Int,
        questionsAnswered: Int) async throws -> GameCompletionRequest{
            
            guard let url = URL(string: "\(baseURL)/sessions") else {
                throw NetworkError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            guard let token = try await Auth.auth().currentUser?.getIDToken() else {
                        print("🚨 User is not logged in or token is missing.")
                        throw NetworkError.unauthorized
                    }
                    
                    // 🚀 THE FIX: 2. Staple the pass to the HTTP Header
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let body: [String: Any] = ["user_id": userId,
                                       "route_id": routeId,
                                       "total_earnings": totalEarnings,
                                       "strikes": strikes,
                                       "questions_answered": questionsAnswered]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode)
            else {
                throw NetworkError.serverError(
                    (response as? HTTPURLResponse)?.statusCode ?? -1
                )
            }
            do {
                do {
                            let decodedResponse = try JSONDecoder().decode(GameCompletionRequest.self, from: data)
                            return decodedResponse
                        } catch let DecodingError.keyNotFound(key, context) {
                            print("🚨 SWIFT DECODING ERROR: Missing key '\(key.stringValue)' - \(context.debugDescription)")
                            throw NetworkError.decodingError // Or whatever your error 3 is
                        } catch let DecodingError.typeMismatch(type, context) {
                            print("🚨 SWIFT DECODING ERROR: Type mismatch for type \(type) - \(context.debugDescription)")
                            throw NetworkError.decodingError
                        } catch {
                            print("🚨 SWIFT DECODING ERROR: \(error.localizedDescription)")
                            throw NetworkError.decodingError
                        }
            } catch {
                throw NetworkError.decodingError
            }
        }
            
        

    /// Fetch current user profile using Bearer token from /users/me endpoint.
    func fetchUserProfile(token: String) async throws -> UserProfile {
        guard let url = URL(string: "\(baseURL)/users/me") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }

        if httpResponse.statusCode == 401 {
            throw NetworkError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            let userProfile = try decoder.decode(UserProfile.self, from: data)
            print("DEBUG: User Profile fetched - \(userProfile.username)")
            return userProfile
        } catch {
            print("🚨 UserProfile Decoding Error: \(error)")
            throw NetworkError.decodingError
        }
    }

    /// Fetch a single destination by ID.
    func fetchDestination(id: String, token: String) async throws
        -> DestinationData
    {
        guard let url = URL(string: "\(baseURL)/destinations/\(id)") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode)
        else {
            throw NetworkError.serverError(
                (response as? HTTPURLResponse)?.statusCode ?? -1
            )
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(DestinationData.self, from: data)
        } catch {
            print("🚨 Destination Decoding Error: \(error)")
            throw NetworkError.decodingError
        }
    }

    /// Fetch route coordinates for a specific destination and difficulty.
    func fetchRouteCoordinates(
        destinationId: String,
        difficulty: String,
        token: String
    ) async throws -> RouteCoordinates {
        guard
            let url = URL(
                string: "\(baseURL)/destinations/\(destinationId)/\(difficulty)"
            )
        else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }

        if httpResponse.statusCode == 401 {
            throw NetworkError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(RouteCoordinates.self, from: data)
        } catch {
            print("🚨 RouteCoordinates Decoding Error: \(error)")
            throw NetworkError.decodingError
        }
    }
    // MARK: - Destinations API

    /// Fetch all destinations from the backend API.
    /// This is a best-effort stub — the backend route and JSON keys must match.
    func fetchDestinations() async throws -> [DestinationResponse] {
        guard let url = URL(string: "\(baseURL)destinations") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode)
        else {
            throw NetworkError.serverError(
                (response as? HTTPURLResponse)?.statusCode ?? -1
            )
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode([DestinationResponse].self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }

    /// Fetch IDs of destinations/routes the user already owns. Returns array of destination IDs.
//    func fetchOwnedDestinationIDs(for userId: String) async throws -> [String] {
//        guard let url = URL(string: "\(baseURL)users/\(userId)/owned") else {
//            throw NetworkError.invalidURL
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue("application/json", forHTTPHeaderField: "accept")
//
//        let (data, response) = try await URLSession.shared.data(for: request)
//        guard let httpResponse = response as? HTTPURLResponse,
//            (200...299).contains(httpResponse.statusCode)
//        else {
//            throw NetworkError.serverError(
//                (response as? HTTPURLResponse)?.statusCode ?? -1
//            )
//        }
//
//        do {
//            let decoder = JSONDecoder()
//            return try decoder.decode([String].self, from: data)
//        } catch {
//            throw NetworkError.decodingError
//        }
//    }

    struct PurchaseResponse: Codable {
        let success: Bool
        let message: String
        let newCoinBalance: Int?
        let destinationId: String?

        enum CodingKeys: String, CodingKey {
            case success
            case message
            case newCoinBalance = "new_coin_balance"
            case destinationId = "destination_id"
        }
    }

    /// Purchase a destination for the user. Returns updated coin balance.
    func purchaseDestination(userId: String, destinationId: String) async throws
        -> PurchaseResponse
    {
        guard let url = URL(string: "\(baseURL)users/\(userId)/purchase") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["destination_id": destinationId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode)
        else {
            throw NetworkError.serverError(
                (response as? HTTPURLResponse)?.statusCode ?? -1
            )
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(PurchaseResponse.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
}
