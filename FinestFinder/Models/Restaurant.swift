import Foundation
import CoreLocation

enum CuisineType: String, Codable, CaseIterable, Identifiable {
    case burger, pizza, italian, korean, vietnamese, japanese, chinese, thai
    case turkish, greek, mexican, german, indian, portuguese, oriental
    case seafood, poke, brunch, steak

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .burger: "🍔"
        case .pizza: "🍕"
        case .italian: "🍝"
        case .korean: "🥘"
        case .vietnamese: "🍜"
        case .japanese: "🍣"
        case .chinese: "🥡"
        case .thai: "🍛"
        case .turkish: "🥙"
        case .greek: "🫒"
        case .mexican: "🌮"
        case .german: "🥨"
        case .indian: "🍛"
        case .portuguese: "🐙"
        case .oriental: "🧆"
        case .seafood: "🐟"
        case .poke: "🥗"
        case .brunch: "🥞"
        case .steak: "🥩"
        }
    }

    var displayName: String {
        switch self {
        default: rawValue.capitalized
        }
    }
}

enum Neighborhood: String, Codable, CaseIterable, Identifiable {
    case altona, ottensen, stPauli, sternschanze, eimsbüttel, neustadt, altstadt
    case winterhude, eppendorf, barmbek, stGeorg, hafenCity, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .stPauli: "St. Pauli"
        case .stGeorg: "St. Georg"
        case .hafenCity: "HafenCity"
        case .eimsbüttel: "Eimsbüttel"
        default: rawValue.capitalized
        }
    }
}

enum PriceRange: String, Codable, CaseIterable, Identifiable {
    case budget, moderate, upscale, fine

    var id: String { rawValue }

    var tier: Int {
        switch self {
        case .budget: 1
        case .moderate: 2
        case .upscale: 3
        case .fine: 4
        }
    }

    var label: String {
        String(repeating: "€", count: tier)
    }
}

struct Restaurant: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let cuisineType: CuisineType
    let neighborhood: Neighborhood
    let priceRange: PriceRange
    let address: String
    let latitude: Double
    let longitude: Double
    let openingHours: String
    let isClosed: Bool
    let notes: String
    let imageUrl: String?
    let personalRating: Double?
    let googleRating: Double?
    let googleReviewCount: Int?
    let googlePlaceId: String?
    let googleMapsUrl: String?
    let createdAt: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var ratings: [Rating] {
        var result: [Rating] = []
        if let pr = personalRating {
            result.append(Rating(source: .personal, value: pr))
        }
        if let gr = googleRating {
            result.append(Rating(source: .google, value: gr, reviewCount: googleReviewCount))
        }
        return result
    }

    func rating(for source: RatingSource) -> Rating? {
        ratings.first { $0.source == source }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, address, latitude, longitude, notes
        case cuisineType = "cuisine_type"
        case neighborhood
        case priceRange = "price_range"
        case openingHours = "opening_hours"
        case isClosed = "is_closed"
        case imageUrl = "image_url"
        case personalRating = "personal_rating"
        case googleRating = "google_rating"
        case googleReviewCount = "google_review_count"
        case googlePlaceId = "google_place_id"
        case googleMapsUrl = "google_maps_url"
        case createdAt = "created_at"
    }
}
