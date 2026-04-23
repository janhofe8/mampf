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
    @State private var isZoomedIn = false
    @State private var currentSpan: Double = 0.06
    @State private var showRatingFilter = false
    @FocusState private var searchFocused: Bool
    // Cached results — updated only when inputs change
    @State private var cachedFiltered: [Restaurant] = []
    @State private var cachedAnnotations: [MapCluster] = []

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

            ForEach(cachedAnnotations) { cluster in
                Annotation(cluster.label, coordinate: cluster.coordinate) {
                    annotationContent(for: cluster)
                }
            }
        }
        .onMapCameraChange { context in
            let span = context.region.span.latitudeDelta
            currentSpan = span
            let zoomed = span < 0.03
            if zoomed != isZoomedIn {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isZoomedIn = zoomed
                }
            }
            // Dismiss keyboard/filter on map interaction instead of .onTapGesture
            if searchFocused { searchFocused = false }
            if showRatingFilter {
                withAnimation { showRatingFilter = false }
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
        .onChange(of: isZoomedIn) { refreshAnnotations() }
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
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
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
                showRatingFilter.toggle()
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

    // MARK: - Annotation Content

    @ViewBuilder
    private func annotationContent(for cluster: MapCluster) -> some View {
        if cluster.isCluster {
            clusterPin(count: cluster.count, topRating: cluster.topRating)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        position = .region(MKCoordinateRegion(
                            center: cluster.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: currentSpan * 0.4, longitudeDelta: currentSpan * 0.4)
                        ))
                    }
                }
        } else if let restaurant = cluster.restaurants.first {
            mapPin(for: restaurant)
                .accessibilityLabel("\(restaurant.name), \(restaurant.cuisineType.displayName)")
                .accessibilityAddTraits(.isButton)
                .onTapGesture {
                    selectedRestaurant = restaurant
                }
        }
    }

    // MARK: - Clustering

    /// Fixed grid size (~600m) so cluster IDs stay stable across zoom changes
    private static let clusterGridSize: Double = 0.008

    private func refreshAnnotations() {
        let filtered = filterVM.apply(to: store.restaurants, userLocation: locationManager.lastLocation, communityRatings: store.communityRatings)
        cachedFiltered = filtered

        guard !isZoomedIn else {
            cachedAnnotations = filtered.map { MapCluster(id: $0.id.uuidString, restaurants: [$0]) }
            return
        }
        let gs = Self.clusterGridSize
        var grid: [String: [Restaurant]] = [:]
        for r in filtered {
            let gx = Int((r.longitude / gs).rounded(.down))
            let gy = Int((r.latitude / gs).rounded(.down))
            grid["c\(gx),\(gy)", default: []].append(r)
        }
        cachedAnnotations = grid.map { key, restaurants in
            let id = restaurants.count == 1 ? restaurants[0].id.uuidString : key
            return MapCluster(id: id, restaurants: restaurants)
        }
    }

    @ViewBuilder
    private func clusterPin(count: Int, topRating: Double?) -> some View {
        let color: Color = topRating.map { .ratingColor(for: $0) } ?? .ffMuted
        Circle()
            .fill(color)
            .frame(width: 32, height: 32)
            .overlay {
                Text("\(count)")
                    .font(.system(size: 13, weight: .black).monospacedDigit())
                    .foregroundStyle(.white)
            }
            .overlay {
                Circle().strokeBorder(.white, lineWidth: 2.5)
            }
    }

    // MARK: - Map Pins

    @ViewBuilder
    private func mapPin(for restaurant: Restaurant) -> some View {
        let color = annotationColor(for: restaurant)
        if isZoomedIn, let rating = restaurant.personalRating {
            Text(rating.formattedRating)
                .font(.system(size: 11, weight: .black).monospacedDigit())
                .foregroundStyle(Color.ratingTextColor(for: rating))
                .frame(minWidth: 28, minHeight: 28)
                .background(color, in: Circle())
                .overlay { Circle().strokeBorder(.white, lineWidth: 1.5) }
        } else {
            Circle()
                .fill(color)
                .frame(width: 14, height: 14)
                .overlay { Circle().strokeBorder(.white, lineWidth: 1.5) }
        }
    }

    private func annotationColor(for restaurant: Restaurant) -> Color {
        guard let rating = restaurant.personalRating else { return .ffMuted }
        return .ratingColor(for: rating)
    }
}

// MARK: - Clustering Model

private struct MapCluster: Identifiable {
    /// Stable ID: single restaurant uses its UUID, clusters use grid key
    let id: String
    let restaurants: [Restaurant]

    var count: Int { restaurants.count }
    var isCluster: Bool { count > 1 }
    var label: String { isCluster ? "" : (restaurants.first?.name ?? "") }

    var coordinate: CLLocationCoordinate2D {
        let lat = restaurants.map(\.latitude).reduce(0, +) / Double(restaurants.count)
        let lon = restaurants.map(\.longitude).reduce(0, +) / Double(restaurants.count)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var topRating: Double? {
        restaurants.compactMap(\.personalRating).max()
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
