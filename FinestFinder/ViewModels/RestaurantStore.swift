import Foundation
import Observation

@Observable
final class RestaurantStore {
    private(set) var restaurants: [Restaurant] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    private(set) var communityRatings: [UUID: (average: Double, count: Int)] = [:]
    private(set) var myRatings: [UUID: Double] = [:]

    private let repository = RestaurantRepository()
    private let userRatingRepo = UserRatingRepository()
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

    func communityRating(for restaurant: Restaurant) -> (average: Double, count: Int)? {
        communityRatings[restaurant.id]
    }

    func myRating(for restaurant: Restaurant) -> Double? {
        myRatings[restaurant.id]
    }

    func ratingsIncludingCommunity(for restaurant: Restaurant) -> [Rating] {
        var result = restaurant.ratings
        if let cr = communityRatings[restaurant.id] {
            result.append(Rating(source: .community, value: cr.average, reviewCount: cr.count))
        }
        return result
    }

    func submitRating(for restaurant: Restaurant, rating: Double) async {
        do {
            try await userRatingRepo.submitRating(restaurantId: restaurant.id, rating: rating)
            myRatings[restaurant.id] = rating
            // Refresh community ratings
            if let updated = try? await userRatingRepo.fetchCommunityRatings() {
                communityRatings = updated
            }
        } catch {
            self.error = error
        }
    }

    func loadMyRating(for restaurant: Restaurant) async {
        if let rating = try? await userRatingRepo.fetchMyRating(restaurantId: restaurant.id) {
            myRatings[restaurant.id] = rating
        }
    }

    func load() async {
        // Show cached data immediately while fetching
        let cached = await repository.loadCachedRestaurants()
        if !cached.isEmpty {
            restaurants = cached
        }

        // Always fetch fresh data from Supabase
        await refresh()
    }

    func refresh() async {
        isLoading = true
        error = nil
        do {
            async let fetchedRestaurants = repository.fetchRestaurants()
            async let fetchedCommunity = userRatingRepo.fetchCommunityRatings()

            restaurants = try await fetchedRestaurants
            communityRatings = (try? await fetchedCommunity) ?? [:]
        } catch {
            self.error = error
        }
        isLoading = false
    }
}
