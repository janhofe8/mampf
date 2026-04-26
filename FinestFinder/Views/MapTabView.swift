import SwiftUI
import MapKit

struct MapTabView: View {
    @Environment(FilterViewModel.self) private var filterVM
    @Environment(RestaurantStore.self) private var store
    @Environment(LocationManager.self) private var locationManager
    @State private var selectedRestaurant: Restaurant?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 53.5575, longitude: 9.9620),
        span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
    )
    @State private var searchText = ""
    @State private var showRatingFilter = false
    @State private var showingFilters = false
    @FocusState private var searchFocused: Bool
    @AppStorage("hasSeenLocationPrimer") private var hasSeenLocationPrimer = false
    @State private var showLocationPrimer = false
    // Cached results — updated only when inputs change
    @State private var cachedFiltered: [Restaurant] = []
    @State private var visiblePins: [Restaurant] = []
    @State private var zoomTier: ZoomTier = .medium
    @State private var suggestions: [Restaurant] = []
    @State private var cachedCategories: [(cuisine: CuisineType, count: Int)] = []

    private enum ZoomTier { case far, medium, close }

    // MARK: - Body

    var body: some View {
        @Bindable var vm = filterVM

        ZStack {
            MapKitMapView(
                region: $region,
                pins: visiblePins,
                userLocation: locationManager.lastLocation,
                onTap: { selectedRestaurant = $0 },
                onRegionChange: { newRegion, userInitiated in
                    let newTier = Self.zoomTier(for: newRegion.span.latitudeDelta)
                    if newTier != zoomTier {
                        zoomTier = newTier
                        refreshVisiblePins()
                    }
                    if userInitiated {
                        if searchFocused { searchFocused = false }
                        if showRatingFilter {
                            withAnimation { showRatingFilter = false }
                        }
                    }
                }
            )
            .ignoresSafeArea()
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
        // Bottom-right: location — lifts above the histogram when it's open
        .overlay(alignment: .bottomTrailing) {
            locationButton
                .padding(.bottom, showRatingFilter ? 168 : 0)
                .animation(.easeInOut(duration: 0.2), value: showRatingFilter)
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
            refreshSuggestions()
            if searchText.isEmpty {
                filterVM.activeSearchText = ""
                return
            }
            try? await Task.sleep(for: .milliseconds(250))
            filterVM.activeSearchText = searchText
        }
        .task {
            refreshAnnotations()
            refreshCategories()
            if !hasSeenLocationPrimer && locationManager.authorizationStatus == .notDetermined {
                try? await Task.sleep(for: .milliseconds(800))
                // User may have tapped the location button during the delay, which
                // already calls requestPermission() — re-check before showing.
                if !hasSeenLocationPrimer && locationManager.authorizationStatus == .notDetermined {
                    showLocationPrimer = true
                }
            }
        }
        .sheet(isPresented: $showLocationPrimer) {
            locationPrimerSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: filterInputsToken) { refreshAnnotations() }
        .onChange(of: store.restaurants.count) {
            refreshCategories()
            refreshSuggestions()
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.selection, trigger: selectedRestaurant)
        .sensoryFeedback(.impact(weight: .light), trigger: showRatingFilter)
        .sheet(item: $selectedRestaurant) { restaurant in
            detailSheet(for: restaurant)
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheetView()
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
        h.combine(filterVM.showMyRatedOnly)
        h.combine(store.myRatings.count)
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

    /// Apple-Maps-style: filled when the map is centered on the user (~50 m), outline otherwise.
    private var isCenteredOnUser: Bool {
        guard let userLoc = locationManager.lastLocation else { return false }
        let center = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        let user = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
        return center.distance(from: user) < 50
    }

    private var locationPrimerSheet: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🗺️")
                .font(.system(size: 90))
            VStack(spacing: 12) {
                Text("location.primer.title")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                Text("location.primer.subtitle")
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Spacer()
            VStack(spacing: 8) {
                Button {
                    hasSeenLocationPrimer = true
                    locationManager.requestPermission()
                    showLocationPrimer = false
                } label: {
                    Text("location.primer.allow")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.ffPrimary, in: RoundedRectangle(cornerRadius: 16))
                }
                Button {
                    hasSeenLocationPrimer = true
                    showLocationPrimer = false
                } label: {
                    Text("location.primer.skip")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .padding(.top, 32)
    }

    private var locationButton: some View {
        MapControlButton(icon: isCenteredOnUser ? "location.fill" : "location") {
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestPermission()
            } else {
                locationManager.refreshLocation()
                if let location = locationManager.lastLocation {
                    withAnimation {
                        region = MKCoordinateRegion(
                            center: location,
                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                        )
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
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(Color.ffPrimary, in: Capsule())
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
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
            .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
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
            if searchFocused || !searchText.isEmpty {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        searchFocused = false
                        searchText = ""
                        filterVM.activeSearchText = ""
                    }
                } label: {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.ffPrimary)
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            ZStack(alignment: .leading) {
                if searchText.isEmpty {
                    Text(String(format: String(localized: "search.restaurants"), store.restaurants.count))
                        .font(.system(size: 17))
                        .foregroundStyle(Color(.systemGray2))
                        .allowsHitTesting(false)
                }
                TextField("", text: $searchText)
                    .focused($searchFocused)
                    .textFieldStyle(.plain)
                    .font(.system(size: 17))
                    .onSubmit {
                        if let first = suggestions.first {
                            selectSearchResult(first)
                        }
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
            let capped = Array(suggestions.prefix(8))
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
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(cachedCategories.enumerated()), id: \.element.cuisine) { index, entry in
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            searchText = entry.cuisine.displayName
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Text(entry.cuisine.icon)
                                .font(.system(size: 22))
                                .frame(width: 36)
                            Text(entry.cuisine.displayName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(entry.count)")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if index < cachedCategories.count - 1 {
                        Divider().padding(.leading, 66)
                    }
                }
            }
        }
        .frame(maxHeight: 380)
    }

    private func refreshCategories() {
        let counts = Dictionary(grouping: store.restaurants, by: \.cuisineType)
            .mapValues(\.count)
        cachedCategories = counts
            .sorted { $0.value > $1.value }
            .prefix(8)
            .map { (cuisine: $0.key, count: $0.value) }
    }

    // MARK: - Chip Bar

    private var chipBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filtersChip
                openNowChip
                ratingChip
                if !store.myRatings.isEmpty { myRatingsChip }
                cuisineChip
                priceChip
            }
        }
        .sensoryFeedback(.selection, trigger: filterVM.selectedCuisines)
        .sensoryFeedback(.selection, trigger: filterVM.selectedNeighborhoods)
        .sensoryFeedback(.selection, trigger: filterVM.selectedPriceRanges)
    }

    private var myRatingsChip: some View {
        Button {
            withAnimation { filterVM.showMyRatedOnly.toggle() }
        } label: {
            FilterBarChip(
                icon: "star.fill",
                text: String(localized: "filter.myRatings"),
                isActive: filterVM.showMyRatedOnly,
                showChevron: false
            )
        }
        .sensoryFeedback(.selection, trigger: filterVM.showMyRatedOnly)
    }

    // MARK: - Filter Chips

    private var filtersChip: some View {
        FiltersEntryChip(activeCount: filterVM.activeFilterCount) {
            showingFilters = true
        }
    }

    private var openNowChip: some View {
        Button {
            withAnimation { filterVM.showOpenOnly.toggle() }
        } label: {
            FilterBarChip(
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
            FilterBarChip(
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
            FilterBarChip(icon: "fork.knife", text: label, isActive: active)
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
            FilterBarChip(icon: "eurosign", text: label, isActive: active)
        }
    }

    // MARK: - Search

    private func searchSuggestionRow(for restaurant: Restaurant) -> some View {
        Button {
            selectSearchResult(restaurant)
        } label: {
            HStack(spacing: 10) {
                AsyncRestaurantImage(url: restaurant.imageUrl.flatMap(URL.init), cuisineIcon: restaurant.cuisineType.icon, targetSize: 36)
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

    private func refreshSuggestions() {
        guard !searchText.isEmpty else {
            if !suggestions.isEmpty { suggestions = [] }
            return
        }
        suggestions = RestaurantListView.rankMatches(searchText, in: store.restaurants)
    }

    private func selectSearchResult(_ restaurant: Restaurant) {
        withAnimation(.easeOut(duration: 0.2)) {
            searchFocused = false
            searchText = ""
            filterVM.activeSearchText = ""
        }
        withAnimation {
            region = MKCoordinateRegion(
                center: restaurant.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        }
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            selectedRestaurant = restaurant
        }
    }

    private func refreshAnnotations() {
        cachedFiltered = filterVM.apply(
            to: store.restaurants,
            userLocation: locationManager.lastLocation,
            communityRatings: store.communityRatings,
            myRatedIds: Set(store.myRatings.keys)
        )
        refreshVisiblePins()
    }

    private func refreshVisiblePins() {
        switch zoomTier {
        case .far:
            // Zoomed way out: only show the top spots (rating ≥ 8) so pins don't clump into noise
            visiblePins = cachedFiltered.filter { ($0.personalRating ?? 0) >= 8 }
        case .medium:
            // Default zoom: hide unrated grey dots, keep all rated spots
            visiblePins = cachedFiltered.filter { $0.personalRating != nil }
        case .close:
            // Zoomed in: show everything including unrated
            visiblePins = cachedFiltered
        }
    }

    private static func zoomTier(for latitudeDelta: Double) -> ZoomTier {
        if latitudeDelta > 0.12 { return .far }
        if latitudeDelta > 0.035 { return .medium }
        return .close
    }

}

// MARK: - Supporting Views

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
                .background(Color(.tertiarySystemBackground), in: Circle())
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
