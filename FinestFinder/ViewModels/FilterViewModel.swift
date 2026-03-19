import Foundation
import Observation

enum SortOption: String, CaseIterable, Identifiable {
    case ratingDescending = "Rating ↓"
    case ratingAscending = "Rating ↑"
    case nameAscending = "Name A-Z"
    case nameDescending = "Name Z-A"

    var id: String { rawValue }
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
    var sortOption: SortOption = .ratingDescending

    var hasActiveFilters: Bool {
        !selectedCuisines.isEmpty
            || !selectedNeighborhoods.isEmpty
            || !selectedPriceRanges.isEmpty
            || minimumRating > 0
    }

    func apply(to restaurants: [Restaurant]) -> [Restaurant] {
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

        if minimumRating > 0 {
            result = result.filter { ($0.personalRating ?? 0) >= minimumRating }
        }

        switch sortOption {
        case .ratingDescending:
            result.sort { ($0.personalRating ?? 0) > ($1.personalRating ?? 0) }
        case .ratingAscending:
            result.sort { ($0.personalRating ?? 0) < ($1.personalRating ?? 0) }
        case .nameAscending:
            result.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .nameDescending:
            result.sort { $0.name.localizedCompare($1.name) == .orderedDescending }
        }

        return result
    }

    func clearFilters() {
        selectedCuisines = []
        selectedNeighborhoods = []
        selectedPriceRanges = []
        minimumRating = 0
    }
}
