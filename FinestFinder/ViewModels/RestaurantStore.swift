import Foundation
import Observation

@Observable
final class RestaurantStore {
    private(set) var restaurants: [Restaurant] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    private(set) var communityRatings: [UUID: (average: Double, count: Int)] = [:]
    private(set) var myRatings: [UUID: Double] = [:]
    /// Full list of the signed-in (or anonymous) user's ratings with timestamps — loaded on demand for Profile tab.
    private(set) var myRatingEntries: [MyRatingEntry] = []

    private let repository = RestaurantRepository()
    private let userRatingRepo = UserRatingRepository()
    private let favoritesKey = "favoriteRestaurantIDs"

    @ObservationIgnored private var currentUserId: UUID?

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
        } else {
            result.append(Rating(source: .community, value: nil))
        }
        return result
    }

    func deleteRating(for restaurant: Restaurant) async {
        error = nil
        do {
            try await userRatingRepo.deleteRating(restaurantId: restaurant.id, userId: currentUserId)
            myRatings.removeValue(forKey: restaurant.id)
            myRatingEntries.removeAll { $0.restaurantId == restaurant.id }
            if let updated = try? await userRatingRepo.fetchCommunityRatings() {
                communityRatings = updated
            }
        } catch {
            if !error.isCancellation {
                self.error = error
            }
        }
    }

    func submitRating(for restaurant: Restaurant, rating: Double) async {
        error = nil
        do {
            try await userRatingRepo.submitRating(restaurantId: restaurant.id, rating: rating, userId: currentUserId)
            myRatings[restaurant.id] = rating
            // Refresh community ratings
            if let updated = try? await userRatingRepo.fetchCommunityRatings() {
                communityRatings = updated
            }
            // Keep the Profile-tab list in sync if it's been loaded
            if let idx = myRatingEntries.firstIndex(where: { $0.restaurantId == restaurant.id }) {
                myRatingEntries[idx] = MyRatingEntry(restaurantId: restaurant.id, rating: rating, updatedAt: Date())
            } else if !myRatingEntries.isEmpty {
                myRatingEntries.append(MyRatingEntry(restaurantId: restaurant.id, rating: rating, updatedAt: Date()))
            }
        } catch {
            if !error.isCancellation {
                self.error = error
            }
        }
    }

    func loadMyRating(for restaurant: Restaurant) async {
        if let rating = try? await userRatingRepo.fetchMyRating(restaurantId: restaurant.id, userId: currentUserId) {
            myRatings[restaurant.id] = rating
        }
    }

    /// Load the full set of the caller's ratings. Populates both the lookup map and the ordered list.
    func loadAllMyRatings() async {
        guard let rows = try? await userRatingRepo.fetchAllMyRatings(userId: currentUserId) else { return }
        myRatingEntries = rows.map {
            MyRatingEntry(restaurantId: $0.restaurantId, rating: $0.rating, updatedAt: $0.updatedAt ?? $0.createdAt ?? .distantPast)
        }
        myRatings = Dictionary(uniqueKeysWithValues: myRatingEntries.map { ($0.restaurantId, $0.rating) })
    }

    /// Called by the app whenever auth state changes. Triggers migration on first sign-in.
    func setCurrentUser(_ userId: UUID?) async {
        let previous = currentUserId
        currentUserId = userId
        guard previous != userId else { return }

        // Reset cached state so we re-fetch under the new identity
        myRatings.removeAll()
        myRatingEntries.removeAll()

        // On sign-in (previous == nil), claim any ratings made anonymously on this device
        if previous == nil, let userId {
            do {
                try await userRatingRepo.migrateDeviceRatingsToUser(userId: userId)
            } catch {
                self.error = error
            }
        }
    }

    /// Delete all user data: ratings from server, favorites, device ID
    func deleteAllData() async {
        do {
            try await userRatingRepo.deleteAllRatings(userId: currentUserId)
        } catch {
            if !error.isCancellation {
                self.error = error
            }
        }
        myRatings.removeAll()
        myRatingEntries.removeAll()
        favoriteIDs.removeAll()
        DeviceID.reset()
        if let updated = try? await userRatingRepo.fetchCommunityRatings() {
            communityRatings = updated
        }
    }

    func load() async {
        // Show cached data immediately while fetching
        async let cachedRestaurants = repository.loadCachedRestaurants()
        async let cachedCommunity = userRatingRepo.loadCachedCommunityRatings()
        let (cached, cachedRatings) = await (cachedRestaurants, cachedCommunity)
        if !cached.isEmpty {
            restaurants = cached
        }
        if !cachedRatings.isEmpty {
            communityRatings = cachedRatings
        }

        // Always fetch fresh data from Supabase
        await refresh()
    }

    func refresh() async {
        isLoading = true
        error = nil
        let hadCachedData = !restaurants.isEmpty
        do {
            async let fetchedRestaurants = repository.fetchRestaurants()
            async let fetchedCommunity = userRatingRepo.fetchCommunityRatings()

            restaurants = try await fetchedRestaurants
            communityRatings = (try? await fetchedCommunity) ?? communityRatings
        } catch {
            // If we have cached data, treat network failure as silently offline — no scary toast.
            if !error.isCancellation && !hadCachedData {
                self.error = error
            }
        }
        isLoading = false
    }
}

struct MyRatingEntry: Identifiable, Equatable {
    let restaurantId: UUID
    let rating: Double
    let updatedAt: Date

    var id: UUID { restaurantId }
}

private extension Error {
    /// True for Swift concurrency cancellation or URL cancellation — not a real failure worth surfacing.
    var isCancellation: Bool {
        if self is CancellationError { return true }
        if let urlError = self as? URLError, urlError.code == .cancelled { return true }
        let nsError = self as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled { return true }
        return false
    }
}
