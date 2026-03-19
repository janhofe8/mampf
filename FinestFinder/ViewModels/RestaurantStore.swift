import Foundation
import Observation

@Observable
final class RestaurantStore {
    private(set) var restaurants: [Restaurant] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    private let repository = RestaurantRepository()
    private let favoritesKey = "favoriteRestaurantIDs"

    private var favoriteIDs: Set<UUID> {
        didSet {
            let strings = favoriteIDs.map(\.uuidString)
            UserDefaults.standard.set(Array(strings), forKey: favoritesKey)
        }
    }

    var favorites: [Restaurant] {
        restaurants.filter { favoriteIDs.contains($0.id) }
    }

    init() {
        let strings = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
        self.favoriteIDs = Set(strings.compactMap { UUID(uuidString: $0) })
    }

    func isFavorite(_ restaurant: Restaurant) -> Bool {
        favoriteIDs.contains(restaurant.id)
    }

    func toggleFavorite(_ restaurant: Restaurant) {
        if favoriteIDs.contains(restaurant.id) {
            favoriteIDs.remove(restaurant.id)
        } else {
            favoriteIDs.insert(restaurant.id)
        }
    }

    func load() async {
        let cached = await repository.loadCachedRestaurants()
        if !cached.isEmpty {
            restaurants = cached
        }

        await refresh()
    }

    func refresh() async {
        isLoading = true
        error = nil
        do {
            restaurants = try await repository.fetchRestaurants()
        } catch {
            self.error = error
        }
        isLoading = false
    }
}
