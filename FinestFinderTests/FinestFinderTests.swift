import Testing
import Foundation
import CoreLocation
@testable import MAMPF

// MARK: - Test Helpers

private func makeRestaurant(
    name: String = "Test",
    cuisine: CuisineType = .pizza,
    neighborhood: Neighborhood = .ottensen,
    price: PriceRange = .moderate,
    rating: Double? = 8.0,
    googleRating: Double? = 4.5,
    openingHours: String = "Mon-Sun 10:00-22:00"
) -> Restaurant {
    Restaurant(
        id: UUID(),
        name: name,
        cuisineType: cuisine,
        neighborhood: neighborhood,
        priceRange: price,
        address: "Test 1",
        latitude: 53.55,
        longitude: 9.93,
        openingHours: openingHours,
        isClosed: false,
        notes: "",
        imageUrl: nil,
        personalRating: rating,
        googleRating: googleRating,
        googleReviewCount: nil,
        googlePlaceId: nil,
        googleMapsUrl: nil,
        createdAt: nil
    )
}

// MARK: - FilterViewModel Tests

@Suite("FilterViewModel")
struct FilterViewModelTests {

    @Test("Search filters by name")
    func searchByName() {
        let vm = FilterViewModel()
        vm.activeSearchText = "lokmam"
        let restaurants = [
            makeRestaurant(name: "Lokmam", cuisine: .turkish),
            makeRestaurant(name: "Burger King", cuisine: .burger),
            makeRestaurant(name: "Pizza Hut", cuisine: .pizza)
        ]
        let result = vm.apply(to: restaurants)
        #expect(result.count == 1)
        #expect(result.first?.name == "Lokmam")
    }

    @Test("Search filters by cuisine displayName")
    func searchByCuisine() {
        let vm = FilterViewModel()
        vm.activeSearchText = "burger"
        let restaurants = [
            makeRestaurant(name: "Otto's", cuisine: .burger),
            makeRestaurant(name: "Sushi Bar", cuisine: .japanese)
        ]
        let result = vm.apply(to: restaurants)
        #expect(result.count == 1)
        #expect(result.first?.name == "Otto's")
    }

    @Test("Filter by cuisine type")
    func filterByCuisine() {
        let vm = FilterViewModel()
        vm.selectedCuisines = [.pizza]
        let restaurants = [
            makeRestaurant(name: "A", cuisine: .pizza),
            makeRestaurant(name: "B", cuisine: .burger),
            makeRestaurant(name: "C", cuisine: .pizza)
        ]
        let result = vm.apply(to: restaurants)
        #expect(result.count == 2)
    }

    @Test("Filter by neighborhood")
    func filterByNeighborhood() {
        let vm = FilterViewModel()
        vm.selectedNeighborhoods = [.stPauli]
        let restaurants = [
            makeRestaurant(name: "A", neighborhood: .stPauli),
            makeRestaurant(name: "B", neighborhood: .ottensen)
        ]
        let result = vm.apply(to: restaurants)
        #expect(result.count == 1)
        #expect(result.first?.name == "A")
    }

    @Test("Filter by price range")
    func filterByPrice() {
        let vm = FilterViewModel()
        vm.selectedPriceRanges = [.budget, .moderate]
        let restaurants = [
            makeRestaurant(name: "Cheap", price: .budget),
            makeRestaurant(name: "Mid", price: .moderate),
            makeRestaurant(name: "Fancy", price: .upscale)
        ]
        let result = vm.apply(to: restaurants)
        #expect(result.count == 2)
    }

    @Test("Filter by minimum rating")
    func filterByMinimumRating() {
        let vm = FilterViewModel()
        vm.minimumRating = 8.0
        let restaurants = [
            makeRestaurant(name: "Great", rating: 9.0),
            makeRestaurant(name: "Good", rating: 7.5),
            makeRestaurant(name: "Best", rating: 10.0)
        ]
        let result = vm.apply(to: restaurants)
        #expect(result.count == 2)
        #expect(result.contains { $0.name == "Great" })
        #expect(result.contains { $0.name == "Best" })
    }

    @Test("Sort by name ascending")
    func sortByName() {
        let vm = FilterViewModel()
        vm.sortField = .name
        vm.sortAscending = true
        let restaurants = [
            makeRestaurant(name: "Charlie"),
            makeRestaurant(name: "Alpha"),
            makeRestaurant(name: "Bravo")
        ]
        let result = vm.apply(to: restaurants)
        #expect(result.map(\.name) == ["Alpha", "Bravo", "Charlie"])
    }

    @Test("Sort by MAMPF rating descending (default)")
    func sortByRatingDefault() {
        let vm = FilterViewModel()
        let restaurants = [
            makeRestaurant(name: "Low", rating: 6.0),
            makeRestaurant(name: "High", rating: 9.5),
            makeRestaurant(name: "Mid", rating: 8.0)
        ]
        let result = vm.apply(to: restaurants)
        #expect(result.map(\.name) == ["High", "Mid", "Low"])
    }

    @Test("Combined filters: cuisine + minimum rating")
    func combinedFilters() {
        let vm = FilterViewModel()
        vm.selectedCuisines = [.pizza]
        vm.minimumRating = 8.0
        let restaurants = [
            makeRestaurant(name: "A", cuisine: .pizza, rating: 9.0),
            makeRestaurant(name: "B", cuisine: .pizza, rating: 6.0),
            makeRestaurant(name: "C", cuisine: .burger, rating: 9.5)
        ]
        let result = vm.apply(to: restaurants)
        #expect(result.count == 1)
        #expect(result.first?.name == "A")
    }

    @Test("Clear filters resets all")
    func clearFilters() {
        let vm = FilterViewModel()
        vm.selectedCuisines = [.pizza]
        vm.selectedNeighborhoods = [.altona]
        vm.minimumRating = 7.0
        vm.showOpenOnly = true
        vm.clearFilters()
        #expect(!vm.hasActiveFilters)
    }

    @Test("hasActiveFilters detects active state")
    func hasActiveFilters() {
        let vm = FilterViewModel()
        #expect(!vm.hasActiveFilters)
        vm.selectedCuisines = [.burger]
        #expect(vm.hasActiveFilters)
    }

    @Test("selectSort toggles direction on same field")
    func selectSortToggle() {
        let vm = FilterViewModel()
        vm.selectSort(.name) // sets ascending (default for name)
        #expect(vm.sortAscending == true)
        vm.selectSort(.name) // toggles
        #expect(vm.sortAscending == false)
    }

    @Test("Empty search returns all restaurants")
    func emptySearch() {
        let vm = FilterViewModel()
        vm.activeSearchText = ""
        let restaurants = [makeRestaurant(name: "A"), makeRestaurant(name: "B")]
        let result = vm.apply(to: restaurants)
        #expect(result.count == 2)
    }
}

// MARK: - OpeningHoursParser Tests

@Suite("OpeningHoursParser")
struct OpeningHoursParserTests {

    // Helper to create a specific date (weekday 2=Monday in Calendar)
    private func date(weekday: Int, hour: Int, minute: Int) -> Date {
        var cal = Calendar.current
        cal.timeZone = .current
        var comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        comps.weekday = weekday
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        return cal.date(from: comps)!
    }

    @Test("Simple format: open within range")
    func simpleFormatOpen() {
        // Monday at 14:00, opening Mon-Sun 10:00-22:00
        let result = OpeningHoursParser.status(for: "Mon-Sun 10:00-22:00", at: date(weekday: 2, hour: 14, minute: 0))
        #expect(result == .open)
    }

    @Test("Simple format: closed outside range")
    func simpleFormatClosed() {
        let result = OpeningHoursParser.status(for: "Mon-Sun 10:00-22:00", at: date(weekday: 2, hour: 23, minute: 0))
        #expect(result == .closed)
    }

    @Test("Simple format: closed day")
    func simpleFormatClosedDay() {
        let result = OpeningHoursParser.status(for: "Mon closed", at: date(weekday: 2, hour: 14, minute: 0))
        #expect(result == .closed)
    }

    @Test("Google format: open")
    func googleFormatOpen() {
        let result = OpeningHoursParser.status(for: "Monday: 11:00 AM - 10:00 PM", at: date(weekday: 2, hour: 15, minute: 0))
        #expect(result == .open)
    }

    @Test("Google format: closed")
    func googleFormatClosed() {
        let result = OpeningHoursParser.status(for: "Monday: 11:00 AM - 10:00 PM", at: date(weekday: 2, hour: 23, minute: 0))
        #expect(result == .closed)
    }

    @Test("Empty string returns unknown")
    func emptyUnknown() {
        #expect(OpeningHoursParser.status(for: "") == .unknown)
    }

    @Test("Late night wrap-around (closes after midnight)")
    func lateNightWrapAround() {
        // Open 18:00-02:00, check at 23:00 on Friday
        let result = OpeningHoursParser.status(for: "Fri 18:00-2:00", at: date(weekday: 6, hour: 23, minute: 0))
        #expect(result == .open)
    }

    @Test("Multiple segments separated by semicolons")
    func multipleSegments() {
        let hours = "Monday: 11:00 AM - 3:00 PM; Monday: 5:00 PM - 10:00 PM"
        // 2 PM on Monday → first segment open
        let result1 = OpeningHoursParser.status(for: hours, at: date(weekday: 2, hour: 14, minute: 0))
        #expect(result1 == .open)
        // 4 PM on Monday → gap between segments
        let result2 = OpeningHoursParser.status(for: hours, at: date(weekday: 2, hour: 16, minute: 0))
        #expect(result2 == .closed)
    }

    @Test("Day range: Mon-Fri")
    func dayRange() {
        // Wednesday (weekday 4) at noon
        let result = OpeningHoursParser.status(for: "Mon-Fri 10:00-22:00", at: date(weekday: 4, hour: 12, minute: 0))
        #expect(result == .open)
        // Sunday (weekday 1) at noon → should not match Mon-Fri
        let result2 = OpeningHoursParser.status(for: "Mon-Fri 10:00-22:00", at: date(weekday: 1, hour: 12, minute: 0))
        #expect(result2 == .unknown) // no matching segment
    }

    @Test("minutesUntilClosing returns correct value")
    func minutesUntilClosing() {
        // Mon-Sun 10:00-22:00, check at 21:30 → 30 min until closing
        let mins = OpeningHoursParser.minutesUntilClosing(for: "Mon-Sun 10:00-22:00", at: date(weekday: 2, hour: 21, minute: 30))
        #expect(mins == 30)
    }

    @Test("minutesUntilClosing returns nil when closed")
    func minutesUntilClosingWhenClosed() {
        let mins = OpeningHoursParser.minutesUntilClosing(for: "Mon-Sun 10:00-22:00", at: date(weekday: 2, hour: 23, minute: 0))
        #expect(mins == nil)
    }
}

// MARK: - Restaurant Codable Tests

@Suite("Restaurant Codable")
struct RestaurantCodableTests {

    private let sampleJSON = """
    {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "name": "Lokmam",
        "cuisine_type": "turkish",
        "neighborhood": "ottensen",
        "price_range": "budget",
        "address": "Ottenser Hauptstr. 52",
        "latitude": 53.5520,
        "longitude": 9.9290,
        "opening_hours": "Mon-Sun 10:00-22:00",
        "is_closed": false,
        "notes": "Great kebab",
        "image_url": null,
        "personal_rating": 9.5,
        "google_rating": 4.6,
        "google_review_count": 820,
        "google_place_id": null,
        "google_maps_url": "https://maps.google.com/?cid=12345",
        "created_at": "2024-01-15T10:00:00Z"
    }
    """.data(using: .utf8)!

    @Test("Decodes from snake_case JSON")
    func decodeFromJSON() throws {
        let restaurant = try JSONDecoder().decode(Restaurant.self, from: sampleJSON)
        #expect(restaurant.name == "Lokmam")
        #expect(restaurant.cuisineType == .turkish)
        #expect(restaurant.neighborhood == .ottensen)
        #expect(restaurant.priceRange == .budget)
        #expect(restaurant.personalRating == 9.5)
        #expect(restaurant.googleRating == 4.6)
        #expect(restaurant.googleReviewCount == 820)
        #expect(restaurant.isClosed == false)
        #expect(restaurant.notes == "Great kebab")
    }

    @Test("Encode/Decode roundtrip preserves data")
    func roundtrip() throws {
        let original = try JSONDecoder().decode(Restaurant.self, from: sampleJSON)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Restaurant.self, from: encoded)
        #expect(original == decoded)
    }

    @Test("Computed coordinate is correct")
    func coordinate() throws {
        let restaurant = try JSONDecoder().decode(Restaurant.self, from: sampleJSON)
        #expect(restaurant.coordinate.latitude == 53.5520)
        #expect(restaurant.coordinate.longitude == 9.9290)
    }

    @Test("Ratings computed property includes personal and google")
    func ratingsComputed() throws {
        let restaurant = try JSONDecoder().decode(Restaurant.self, from: sampleJSON)
        #expect(restaurant.ratings.count == 2)
        #expect(restaurant.ratings.contains { $0.source == .personal && $0.value == 9.5 })
        #expect(restaurant.ratings.contains { $0.source == .google && $0.value == 4.6 })
    }

    @Test("Decodes with null optional fields")
    func nullOptionals() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "name": "No Rating",
            "cuisine_type": "pizza",
            "neighborhood": "altona",
            "price_range": "moderate",
            "address": "Test 1",
            "latitude": 53.55,
            "longitude": 9.93,
            "opening_hours": "",
            "is_closed": false,
            "notes": "",
            "image_url": null,
            "personal_rating": null,
            "google_rating": null,
            "google_review_count": null,
            "google_place_id": null,
            "google_maps_url": null,
            "created_at": null
        }
        """.data(using: .utf8)!
        let r = try JSONDecoder().decode(Restaurant.self, from: json)
        #expect(r.personalRating == nil)
        #expect(r.googleRating == nil)
        #expect(r.ratings.isEmpty)
    }
}
