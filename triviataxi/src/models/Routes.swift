//
//  Routes.swift
//  triviataxi
//

import Foundation

// Maps to the destination profile data
struct DestinationData: Codable, Identifiable {
    let id: String
    let city: String
    let country: String
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case city
        case country
        case imageUrl = "image_url"
    }
}

// Maps to the FastAPI response for route coordinates
struct RouteCoordinates: Codable {
    let originLat: Double
    let originLng: Double
    let destinationLat: Double
    let destinationLng: Double

    enum CodingKeys: String, CodingKey {
        case originLat = "origin_lat"
        case originLng = "origin_lng"
        case destinationLat = "destination_lat"
        case destinationLng = "destination_lng"
    }
}

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
