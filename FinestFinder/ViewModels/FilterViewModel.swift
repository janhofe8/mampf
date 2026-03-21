import Foundation
import CoreLocation
import Observation

enum SortOption: String, CaseIterable, Identifiable {
    case ratingDescending, ratingAscending
    case googleRatingDescending, communityRatingDescending
    case recentlyAdded, distanceAscending
    case nameAscending, nameDescending
    case random

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ratingDescending: String(localized: "sort.mampfDesc")
        case .ratingAscending: String(localized: "sort.mampfAsc")
        case .googleRatingDescending: String(localized: "sort.googleDesc")
        case .communityRatingDescending: String(localized: "sort.communityDesc")
        case .recentlyAdded: String(localized: "sort.recentlyAdded")
        case .distanceAscending: String(localized: "sort.distance")
        case .nameAscending: String(localized: "sort.nameAZ")
        case .nameDescending: String(localized: "sort.nameZA")
        case .random: String(localized: "sort.random")
        }
    }
}

extension Set {
    mutating func toggle(_ member: Element) {
        if contains(member) {
            remove(member)
        } else {
            insert(member)
        }
    }
}

@Observable
final class FilterViewModel {
    var searchText = ""
    var selectedCuisines: Set<CuisineType> = []
    var selectedNeighborhoods: Set<Neighborhood> = []
    var selectedPriceRanges: Set<PriceRange> = []
    var minimumRating: Double = 0
    var maximumRating: Double = 10
    var sortOption: SortOption = .ratingDescending {
        didSet {
            if sortOption == .random {
                randomSeed = UUID()
            }
        }
    }
    /// Stable seed for random sort — only changes when user re-selects random
    private(set) var randomSeed = UUID()

    var hasActiveFilters: Bool {
        !selectedCuisines.isEmpty
            || !selectedNeighborhoods.isEmpty
            || !selectedPriceRanges.isEmpty
            || minimumRating > 0
            || maximumRating < 10
    }

    func apply(
        to restaurants: [Restaurant],
        userLocation: CLLocationCoordinate2D? = nil,
        communityRatings: [UUID: (average: Double, count: Int)] = [:]
    ) -> [Restaurant] {
        var result = restaurants

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query)
                    || $0.cuisineType.rawValue.lowercased().contains(query)
                    || $0.cuisineType.displayName.lowercased().contains(query)
                    || $0.neighborhood.rawValue.lowercased().contains(query)
                    || $0.neighborhood.displayName.lowercased().contains(query)
            }
        }

        if !selectedCuisines.isEmpty {
            result = result.filter { selectedCuisines.contains($0.cuisineType) }
        }

        if !selectedNeighborhoods.isEmpty {
            result = result.filter { selectedNeighborhoods.contains($0.neighborhood) }
        }

        if !selectedPriceRanges.isEmpty {
            result = result.filter { selectedPriceRanges.contains($0.priceRange) }
        }

        if minimumRating > 0 || maximumRating < 10 {
            result = result.filter {
                let rating = $0.personalRating ?? 0
                return rating >= minimumRating && rating <= maximumRating
            }
        }

        switch sortOption {
        case .ratingDescending:
            result.sort { ($0.personalRating ?? 0) > ($1.personalRating ?? 0) }
        case .ratingAscending:
            result.sort { ($0.personalRating ?? 0) < ($1.personalRating ?? 0) }
        case .googleRatingDescending:
            result.sort { ($0.googleRating ?? 0) > ($1.googleRating ?? 0) }
        case .communityRatingDescending:
            result.sort { (communityRatings[$0.id]?.average ?? 0) > (communityRatings[$1.id]?.average ?? 0) }
        case .recentlyAdded:
            result.sort { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
        case .distanceAscending:
            if let loc = userLocation {
                let userCL = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
                result.sort {
                    let d0 = userCL.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude))
                    let d1 = userCL.distance(from: CLLocation(latitude: $1.latitude, longitude: $1.longitude))
                    return d0 < d1
                }
            }
        case .nameAscending:
            result.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .nameDescending:
            result.sort { $0.name.localizedCompare($1.name) == .orderedDescending }
        case .random:
            let seed = randomSeed
            result.sort { a, b in
                var h1 = Hasher(); h1.combine(a.id); h1.combine(seed)
                var h2 = Hasher(); h2.combine(b.id); h2.combine(seed)
                return h1.finalize() < h2.finalize()
            }
        }

        return result
    }

    func clearFilters() {
        selectedCuisines = []
        selectedNeighborhoods = []
        selectedPriceRanges = []
        minimumRating = 0
        maximumRating = 10
    }
}
