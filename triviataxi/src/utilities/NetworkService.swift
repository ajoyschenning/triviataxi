//
//  NetworkService.swift
//  triviataxi
//
//  Created by Cami Krugel on 2/20/26.
//

import Foundation

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
    
    // High-standard approach: Use a Result type or Async/Await
    func createSession(journeyId: String, token: String) async throws -> SessionResponse {
        // 1. Construct URL with Query Items
        var components = URLComponents(string: "\(baseURL)/sessions")
        components?.queryItems = [URLQueryItem(name: "journey_id", value: journeyId)]
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        // 2. Setup Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // 3. Execute Request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 4. Validate Response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        if httpResponse.statusCode == 401 {
            throw NetworkError.unauthorized
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        // 5. Decode JSON
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(SessionResponse.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw NetworkError.decodingError
        }
    }

    // MARK: - Shop / Destinations API Stubs

    struct DestinationResponse: Codable, Identifiable {
        let id: String
        let city: String
        let miles: String?
        let price: Int
        let imageUrl: String?

        enum CodingKeys: String, CodingKey {
            case id
            case city
            case miles
            case price
            case imageUrl = "image_url"
        }
    }

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
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError((response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode([DestinationResponse].self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }

    /// Fetch IDs of destinations/routes the user already owns. Returns array of destination IDs.
    func fetchOwnedDestinationIDs(for userId: String) async throws -> [String] {
        guard let url = URL(string: "\(baseURL)users/\(userId)/owned_destinations") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError((response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode([String].self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }

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
    func purchaseDestination(userId: String, destinationId: String) async throws -> PurchaseResponse {
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
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError((response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(PurchaseResponse.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
}
