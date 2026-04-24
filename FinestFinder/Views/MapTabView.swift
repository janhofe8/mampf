import SwiftUI
import MapKit

struct MapTabView: View {
    @Environment(FilterViewModel.self) private var filterVM
    @Environment(RestaurantStore.self) private var store
    @Environment(LocationManager.self) private var locationManager
    @State private var selectedRestaurant: Restaurant?
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 53.5575, longitude: 9.9620),
            span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
        )
    )
    @State private var searchText = ""
    @State private var showRatingFilter = false
    @State private var mapDragged = false
    @FocusState private var searchFocused: Bool
    // Cached results — updated only when inputs change
    @State private var cachedFiltered: [Restaurant] = []

    // MARK: - Body

    var body: some View {
        @Bindable var vm = filterVM

        Map(position: $position) {
            if let location = locationManager.lastLocation {
                Annotation(String(localized: "map.myLocation"), coordinate: location) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().strokeBorder(.white, lineWidth: 2.5))
                }
            }

            ForEach(cachedFiltered) { restaurant in
                Annotation(restaurant.name, coordinate: CLLocationCoordinate2D(latitude: restaurant.latitude, longitude: restaurant.longitude)) {
                    mapPin(for: restaurant)
                        .accessibilityLabel("\(restaurant.name), \(restaurant.cuisineType.displayName)")
                        .accessibilityAddTraits(.isButton)
                        .onTapGesture {
                            selectedRestaurant = restaurant
                        }
                }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 10)
                .onChanged { _ in mapDragged = true }
        )
        .onMapCameraChange { _ in
            // Only dismiss UI on genuine user drag — avoids keyboard-induced layout changes killing focus
            if mapDragged {
                if searchFocused { searchFocused = false }
                if showRatingFilter {
                    withAnimation { showRatingFilter = false }
                }
                mapDragged = false
            }
        }
        // Top: search + chips
        .overlay(alignment: .top) {
            topOverlay
        }
        // Rating histogram
        .overlay(alignment: .bottom) {
            if showRatingFilter {
                RatingHistogramFilter(
                    restaurants: store.restaurants,
                    minimumRating: $vm.minimumRating,
                    matchCount: cachedFiltered.count,
                    onDismiss: { withAnimation { showRatingFilter = false } }
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // Bottom-right: location
        .overlay(alignment: .bottomTrailing) {
            locationButton
        }
        // Empty-state banner when filters produce zero matches
        .overlay(alignment: .center) {
            if cachedFiltered.isEmpty && !store.restaurants.isEmpty && !searchFocused {
                emptyBanner
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: cachedFiltered.isEmpty)
        .task(id: searchText) {
            if searchText.isEmpty {
                filterVM.activeSearchText = ""
                return
            }
            try? await Task.sleep(for: .milliseconds(250))
            filterVM.activeSearchText = searchText
        }
        .task { refreshAnnotations() }
        .onChange(of: filterInputsToken) { refreshAnnotations() }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.selection, trigger: selectedRestaurant)
        .sensoryFeedback(.impact(weight: .light), trigger: showRatingFilter)
        .sheet(item: $selectedRestaurant) { restaurant in
            detailSheet(for: restaurant)
        }
    }

    /// Hash of all filter/data inputs — single onChange instead of 12 separate ones
    private var filterInputsToken: Int {
        var h = Hasher()
        h.combine(store.restaurants.count)
        h.combine(filterVM.activeSearchText)
        h.combine(filterVM.selectedCuisines)
        h.combine(filterVM.selectedNeighborhoods)
        h.combine(filterVM.selectedPriceRanges)
        h.combine(filterVM.minimumRating)
        h.combine(filterVM.showOpenOnly)
        return h.finalize()
    }

    private func detailSheet(for restaurant: Restaurant) -> some View {
        NavigationStack {
            RestaurantDetailView(restaurant: restaurant)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("nav.done") { selectedRestaurant = nil }
                            .foregroundStyle(.ffPrimary)
                    }
                }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Location Button

    private var locationButton: some View {
        MapControlButton(icon: "location.fill") {
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestPermission()
            } else {
                locationManager.refreshLocation()
                if let location = locationManager.lastLocation {
                    withAnimation {
                        position = .region(MKCoordinateRegion(
                            center: location,
                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                        ))
                    }
                }
            }
        }
        .padding(.trailing, 12)
        .padding(.bottom, 16)
    }

    // MARK: - Empty Banner

    private var emptyBanner: some View {
        VStack(spacing: 10) {
            Image(systemName: "map")
                .font(.system(size: 32))
                .foregroundStyle(Color.ffPrimary.opacity(0.7))
            Text("empty.mapNoMatches.title")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
            Text("empty.mapNoMatches.message")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if filterVM.hasActiveFilters {
                Button {
                    withAnimation {
                        filterVM.clearFilters()
                        showRatingFilter = false
                    }
                } label: {
                    Text("empty.noResults.cta")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.ffPrimary, in: Capsule())
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 3)
        .padding(.horizontal, 40)
    }

    // MARK: - Top Overlay

    @ViewBuilder
    private var topOverlay: some View {
        let showingDropdown = searchFocused || !searchText.isEmpty

        VStack(spacing: 8) {
            // Search card
            VStack(spacing: 0) {
                searchBarRow
                if showingDropdown {
                    Divider().padding(.horizontal, 12)
                    searchDropdownContent
                }
            }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 2)

            // Chip bar (hide when dropdown open)
            if !showingDropdown {
                chipBar
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .animation(.easeInOut(duration: 0.2), value: showingDropdown)
    }

    private var searchBarRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)
            TextField(
                String(format: String(localized: "search.restaurants"), store.restaurants.count),
                text: $searchText
            )
            .focused($searchFocused)
            .textFieldStyle(.plain)
            .font(.system(size: 17))
            .onSubmit {
                if let first = searchSuggestions.first {
                    selectSearchResult(first)
                }
            }
            if searchFocused || !searchText.isEmpty {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        searchFocused = false
                        searchText = ""
                        filterVM.activeSearchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var searchDropdownContent: some View {
        if searchText.isEmpty {
            // Category suggestions when focused but empty
            categorySuggestions
        } else {
            // Restaurant results when typing
            let capped = Array(searchSuggestions.prefix(8))
            if capped.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                    Text("search.noResults")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(capped.enumerated()), id: \.element.id) { index, restaurant in
                            searchSuggestionRow(for: restaurant)
                            if index < capped.count - 1 {
                                Divider().padding(.leading, 52)
                            }
                        }
                    }
                }
                .frame(maxHeight: 380)
            }
        }
    }

    /// Popular categories sorted by restaurant count
    private var categorySuggestions: some View {
        let counts = Dictionary(grouping: store.restaurants, by: \.cuisineType)
            .mapValues(\.count)
        let sorted = counts.sorted { $0.value > $1.value }.prefix(8)

        return ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(sorted.enumerated()), id: \.element.key) { index, entry in
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            searchText = entry.key.displayName
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Text(entry.key.icon)
                                .font(.system(size: 22))
                                .frame(width: 36)
                            Text(entry.key.displayName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(entry.value)")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if index < sorted.count - 1 {
                        Divider().padding(.leading, 66)
                    }
                }
            }
        }
        .frame(maxHeight: 380)
    }

    // MARK: - Chip Bar

    private var chipBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                openNowChip
                ratingChip
                cuisineChip
                priceChip

                if filterVM.hasActiveFilters {
                    Button {
                        withAnimation {
                            filterVM.clearFilters()
                            showRatingFilter = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(.regularMaterial, in: Circle())
                            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .sensoryFeedback(.selection, trigger: filterVM.selectedCuisines)
        .sensoryFeedback(.selection, trigger: filterVM.selectedNeighborhoods)
        .sensoryFeedback(.selection, trigger: filterVM.selectedPriceRanges)
    }

    // MARK: - Filter Chips

    private var openNowChip: some View {
        Button {
            withAnimation { filterVM.showOpenOnly.toggle() }
        } label: {
            MapChip(
                icon: "clock.fill",
                text: String(localized: "filter.openNow"),
                isActive: filterVM.showOpenOnly,
                showChevron: false
            )
        }
        .sensoryFeedback(.selection, trigger: filterVM.showOpenOnly)
    }

    private var ratingChip: some View {
        let active = filterVM.minimumRating > 0

        return Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                if active {
                    // Active chip → tap clears the filter (no histogram step needed)
                    filterVM.minimumRating = 0
                    showRatingFilter = false
                } else {
                    showRatingFilter.toggle()
                }
            }
        } label: {
            MapChip(
                icon: "star.fill",
                text: active ? "≥ \(filterVM.minimumRating.formattedRating)" : String(localized: "filter.rating"),
                isActive: active || showRatingFilter,
                showChevron: false
            )
        }
        .sensoryFeedback(.impact(weight: .light), trigger: showRatingFilter)
        .sensoryFeedback(.selection, trigger: filterVM.minimumRating)
    }

    private var cuisineChip: some View {
        let count = filterVM.selectedCuisines.count
        let active = count > 0
        let label: String
        if count == 1, let c = filterVM.selectedCuisines.first {
            label = "\(c.icon) \(c.displayName)"
        } else if active {
            label = String(localized: "filter.cuisine") + " · \(count)"
        } else {
            label = String(localized: "filter.cuisine")
        }

        return Menu {
            ForEach(CuisineType.allCases) { cuisine in
                Button {
                    withAnimation { filterVM.selectedCuisines.toggle(cuisine) }
                } label: {
                    if filterVM.selectedCuisines.contains(cuisine) {
                        Label("\(cuisine.icon) \(cuisine.displayName)", systemImage: "checkmark")
                    } else {
                        Text("\(cuisine.icon) \(cuisine.displayName)")
                    }
                }
            }
        } label: {
            MapChip(icon: "fork.knife", text: label, isActive: active)
        }
    }

    private var priceChip: some View {
        let count = filterVM.selectedPriceRanges.count
        let active = count > 0
        let label: String
        if count == 1, let p = filterVM.selectedPriceRanges.first {
            label = p.label
        } else if active {
            label = String(localized: "filter.priceRange") + " · \(count)"
        } else {
            label = String(localized: "filter.priceRange")
        }

        return Menu {
            ForEach(PriceRange.allCases) { price in
                Button {
                    withAnimation { filterVM.selectedPriceRanges.toggle(price) }
                } label: {
                    if filterVM.selectedPriceRanges.contains(price) {
                        Label(price.label, systemImage: "checkmark")
                    } else {
                        Text(price.label)
                    }
                }
            }
        } label: {
            MapChip(icon: "eurosign", text: label, isActive: active)
        }
    }

    // MARK: - Search

    private func searchSuggestionRow(for restaurant: Restaurant) -> some View {
        Button {
            selectSearchResult(restaurant)
        } label: {
            HStack(spacing: 10) {
                AsyncRestaurantImage(url: restaurant.imageUrl.flatMap(URL.init), cuisineIcon: restaurant.cuisineType.icon)
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(restaurant.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Text(restaurant.cuisineType.icon)
                            .font(.system(size: 11))
                        Text(restaurant.neighborhood.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text(restaurant.priceRange.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let rating = restaurant.personalRating {
                    RatingPill(icon: "star.fill", value: rating.formattedRating, color: RatingSource.personal.color, textColor: .white, size: .compact)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var searchSuggestions: [Restaurant] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return store.restaurants
            .filter {
                $0.name.lowercased().contains(query)
                    || $0.cuisineType.displayName.lowercased().contains(query)
                    || $0.neighborhood.displayName.lowercased().contains(query)
            }
            .sorted { ($0.personalRating ?? 0) > ($1.personalRating ?? 0) }
    }

    private func selectSearchResult(_ restaurant: Restaurant) {
        withAnimation(.easeOut(duration: 0.2)) {
            searchFocused = false
            searchText = ""
            filterVM.activeSearchText = ""
        }
        withAnimation {
            position = .region(MKCoordinateRegion(
                center: restaurant.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))
        }
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            selectedRestaurant = restaurant
        }
    }

    private func refreshAnnotations() {
        cachedFiltered = filterVM.apply(to: store.restaurants, userLocation: locationManager.lastLocation, communityRatings: store.communityRatings)
    }

    // MARK: - Map Pins

    @ViewBuilder
    private func mapPin(for restaurant: Restaurant) -> some View {
        if let rating = restaurant.personalRating {
            Text(rating.formattedRating)
                .font(.system(size: 11, weight: .black).monospacedDigit())
                .foregroundStyle(Color.ratingTextColor(for: rating))
                .frame(minWidth: 28, minHeight: 28)
                .background(Color.ratingColor(for: rating), in: Circle())
                .overlay { Circle().strokeBorder(.white, lineWidth: 1.5) }
        } else {
            Circle()
                .fill(Color.ffMuted)
                .frame(width: 14, height: 14)
                .overlay { Circle().strokeBorder(.white, lineWidth: 1.5) }
        }
    }
}

// MARK: - Supporting Views

private struct MapChip: View {
    let icon: String
    let text: String
    let isActive: Bool
    var showChevron: Bool = true

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            if showChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isActive ? AnyShapeStyle(Color.ffPrimary) : AnyShapeStyle(.regularMaterial), in: Capsule())
        .foregroundStyle(isActive ? .white : .primary)
        .shadow(color: .black.opacity(isActive ? 0 : 0.08), radius: 4, y: 2)
    }
}

private struct MapControlButton: View {
    let icon: String
    var tint: Color = .ffPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
    }
}

#Preview {
    NavigationStack {
        MapTabView()
    }
    .environment(FilterViewModel())
    .environment(RestaurantStore())
    .environment(LocationManager())
}
