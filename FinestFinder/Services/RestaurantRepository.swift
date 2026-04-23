import Foundation
import Supabase

actor RestaurantRepository {
    private let cacheURL: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("restaurants_cache.json")
    }()

    private static let columns = "id,name,cuisine_type,neighborhood,price_range,address,latitude,longitude,opening_hours,is_closed,notes,image_url,personal_rating,google_rating,google_review_count,google_place_id,google_maps_url,created_at"

    func fetchRestaurants() async throws -> [Restaurant] {
        let restaurants: [Restaurant] = try await SupabaseManager.shared.client
            .from("restaurants")
            .select(Self.columns)
            .execute()
            .value
        cacheRestaurants(restaurants)
        return restaurants
    }

    /// Offline fallback only
    func loadCachedRestaurants() -> [Restaurant] {
        guard let data = try? Data(contentsOf: cacheURL),
              let restaurants = try? Self.decoder.decode([Restaurant].self, from: data)
        else { return [] }
        return restaurants
    }

    private func cacheRestaurants(_ restaurants: [Restaurant]) {
        guard let data = try? Self.encoder.encode(restaurants) else { return }
        try? data.write(to: cacheURL)
    }

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}
