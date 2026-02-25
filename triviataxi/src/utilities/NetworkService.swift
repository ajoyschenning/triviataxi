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
}
