import Foundation
import Supabase

actor RestaurantRepository {
    private let cacheURL: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("restaurants_cache.json")
    }()

    func fetchRestaurants() async throws -> [Restaurant] {
        let restaurants: [Restaurant] = try await SupabaseManager.shared.client
            .from("restaurants")
            .select()
            .execute()
            .value
        cacheRestaurants(restaurants)
        return restaurants
    }

    /// Offline fallback only
    func loadCachedRestaurants() -> [Restaurant] {
        guard let data = try? Data(contentsOf: cacheURL),
              let restaurants = try? JSONDecoder().decode([Restaurant].self, from: data)
        else { return [] }
        return restaurants
    }

    private func cacheRestaurants(_ restaurants: [Restaurant]) {
        guard let data = try? JSONEncoder().encode(restaurants) else { return }
        try? data.write(to: cacheURL)
    }
}
