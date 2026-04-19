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
    var maximumRating: Double = 10
    var showOpenOnly: Bool = false
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
            || maximumRating < 10
            || showOpenOnly
    }

    func apply(
        to restaurants: [Restaurant],
        userLocation: CLLocationCoordinate2D? = nil,
        communityRatings: [UUID: (average: Double, count: Int)] = [:]
    ) -> [Restaurant] {
        var result = filter(restaurants)
        sort(&result, userLocation: userLocation, communityRatings: communityRatings)
        return result
    }

    private func filter(_ restaurants: [Restaurant]) -> [Restaurant] {
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

        if minimumRating > 0 || maximumRating < 10 {
            result = result.filter {
                let rating = $0.personalRating ?? 0
                return rating >= minimumRating && rating <= maximumRating
            }
        }

        if showOpenOnly {
            result = result.filter { $0.openingStatus == .open }
        }

        return result
    }

    private func sort(
        _ result: inout [Restaurant],
        userLocation: CLLocationCoordinate2D?,
        communityRatings: [UUID: (average: Double, count: Int)]
    ) {
        let asc = sortAscending
        switch sortField {
        case .mampfRating:
            result.sort { asc ? ($0.personalRating ?? 0) < ($1.personalRating ?? 0)
                              : ($0.personalRating ?? 0) > ($1.personalRating ?? 0) }
        case .googleRating:
            result.sort { asc ? ($0.googleRating ?? 0) < ($1.googleRating ?? 0)
                              : ($0.googleRating ?? 0) > ($1.googleRating ?? 0) }
        case .communityRating:
            result.sort { asc ? (communityRatings[$0.id]?.average ?? 0) < (communityRatings[$1.id]?.average ?? 0)
                              : (communityRatings[$0.id]?.average ?? 0) > (communityRatings[$1.id]?.average ?? 0) }
        case .recentlyAdded:
            result.sort { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
        case .distance:
            if let loc = userLocation {
                let userCL = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
                result.sort {
                    let d0 = userCL.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude))
                    let d1 = userCL.distance(from: CLLocation(latitude: $1.latitude, longitude: $1.longitude))
                    return asc ? d0 < d1 : d0 > d1
                }
            }
        case .name:
            result.sort { asc ? $0.name.localizedCompare($1.name) == .orderedAscending
                              : $0.name.localizedCompare($1.name) == .orderedDescending }
        case .random:
            let seed = randomSeed
            result.sort { a, b in
                var h1 = Hasher(); h1.combine(a.id); h1.combine(seed)
                var h2 = Hasher(); h2.combine(b.id); h2.combine(seed)
                return h1.finalize() < h2.finalize()
            }
        }
    }

    func clearFilters() {
        selectedCuisines = []
        selectedNeighborhoods = []
        selectedPriceRanges = []
        minimumRating = 0
        maximumRating = 10
        showOpenOnly = false
    }
}
