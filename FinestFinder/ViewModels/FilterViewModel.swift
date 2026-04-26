import Foundation
import CoreLocation
import Observation

enum SortField: String, CaseIterable, Identifiable {
    case mampfRating, googleRating, communityRating
    case recentlyAdded, distance
    case name
    case random

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mampfRating: String(localized: "sort.mampfRating")
        case .googleRating: String(localized: "sort.googleRating")
        case .communityRating: String(localized: "sort.communityRating")
        case .recentlyAdded: String(localized: "sort.recentlyAdded")
        case .distance: String(localized: "sort.distance")
        case .name: String(localized: "sort.name")
        case .random: String(localized: "sort.random")
        }
    }

    var icon: String {
        switch self {
        case .mampfRating: "star.fill"
        case .googleRating: "globe"
        case .communityRating: "person.2.fill"
        case .recentlyAdded: "clock"
        case .distance: "location"
        case .name: "textformat.abc"
        case .random: "shuffle"
        }
    }

    /// Whether this field supports ascending/descending toggle
    var supportsDirection: Bool {
        switch self {
        case .random, .recentlyAdded: false
        default: true
        }
    }

    /// Default: ratings descending (highest first), name/distance ascending
    var defaultAscending: Bool {
        switch self {
        case .name, .distance: true
        default: false
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
    var activeSearchText = ""
    var selectedCuisines: Set<CuisineType> = []
    var selectedNeighborhoods: Set<Neighborhood> = []
    var selectedPriceRanges: Set<PriceRange> = []
    var minimumRating: Double = 0
    var showOpenOnly: Bool = false
    var showMyRatedOnly: Bool = false
    var sortField: SortField = .mampfRating
    var sortAscending: Bool = false
    /// Stable seed for random sort — only changes when user re-selects random
    private(set) var randomSeed = UUID()

    /// Select a sort field. If already selected, toggle direction. Otherwise set with default direction.
    func selectSort(_ field: SortField) {
        if sortField == field && field.supportsDirection {
            sortAscending.toggle()
        } else {
            sortField = field
            sortAscending = field.defaultAscending
            if field == .random {
                randomSeed = UUID()
            }
        }
    }

    var hasActiveFilters: Bool {
        !selectedCuisines.isEmpty
            || !selectedNeighborhoods.isEmpty
            || !selectedPriceRanges.isEmpty
            || minimumRating > 0
            || showOpenOnly
            || showMyRatedOnly
    }

    /// Count of currently-applied filter dimensions — shown as a badge on the "Filters" chip.
    var activeFilterCount: Int {
        var count = 0
        if !selectedCuisines.isEmpty { count += 1 }
        if !selectedNeighborhoods.isEmpty { count += 1 }
        if !selectedPriceRanges.isEmpty { count += 1 }
        if minimumRating > 0 { count += 1 }
        if showOpenOnly { count += 1 }
        if showMyRatedOnly { count += 1 }
        return count
    }

    func apply(
        to restaurants: [Restaurant],
        userLocation: CLLocationCoordinate2D? = nil,
        communityRatings: [UUID: (average: Double, count: Int)] = [:],
        myRatedIds: Set<UUID> = []
    ) -> [Restaurant] {
        var result = filter(restaurants, myRatedIds: myRatedIds)
        sort(&result, userLocation: userLocation, communityRatings: communityRatings)
        return result
    }

    private func filter(_ restaurants: [Restaurant], myRatedIds: Set<UUID>) -> [Restaurant] {
        var result = restaurants

        if !activeSearchText.isEmpty {
            let query = activeSearchText
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(query)
                    || $0.cuisineType.rawValue.localizedCaseInsensitiveContains(query)
                    || $0.cuisineType.displayName.localizedCaseInsensitiveContains(query)
                    || $0.neighborhood.displayName.localizedCaseInsensitiveContains(query)
                    || $0.priceRange.label.contains(query)
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

        if minimumRating > 0 {
            result = result.filter { ($0.personalRating ?? 0) >= minimumRating }
        }

        if showOpenOnly {
            result = result.filter { $0.openingStatus == .open }
        }

        if showMyRatedOnly {
            result = result.filter { myRatedIds.contains($0.id) }
        }

        return result
    }

    private func sort(
        _ result: inout [Restaurant],
        userLocation: CLLocationCoordinate2D?,
        communityRatings: [UUID: (average: Double, count: Int)]
    ) {
        switch sortField {
        case .mampfRating:
            sortBy(&result) { $0.personalRating ?? 0 }
        case .googleRating:
            sortBy(&result) { $0.googleRating ?? 0 }
        case .communityRating:
            sortBy(&result) { communityRatings[$0.id]?.average ?? 0 }
        case .recentlyAdded:
            result.sort { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        case .distance:
            guard let loc = userLocation else { return }
            let userCL = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
            sortBy(&result) {
                userCL.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude))
            }
        case .name:
            sortBy(&result) { $0.name }
        case .random:
            let seed = randomSeed
            result.sort { a, b in
                var h1 = Hasher(); h1.combine(a.id); h1.combine(seed)
                var h2 = Hasher(); h2.combine(b.id); h2.combine(seed)
                return h1.finalize() < h2.finalize()
            }
        }
    }

    /// Sort in-place by a Comparable key, honoring `sortAscending`.
    private func sortBy<T: Comparable>(_ result: inout [Restaurant], key: (Restaurant) -> T) {
        result.sort { sortAscending ? key($0) < key($1) : key($0) > key($1) }
    }

    func clearFilters() {
        selectedCuisines = []
        selectedNeighborhoods = []
        selectedPriceRanges = []
        minimumRating = 0
        showOpenOnly = false
        showMyRatedOnly = false
    }
}
