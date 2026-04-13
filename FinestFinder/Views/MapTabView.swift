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
    @State private var isZoomedIn = false
    @State private var showRatingFilter = false
    @FocusState private var searchFocused: Bool
    @State private var pulseAnimation = false

    private var filtered: [Restaurant] {
        filterVM.apply(to: store.restaurants, userLocation: locationManager.lastLocation, communityRatings: store.communityRatings)
    }

    // MARK: - Body

    var body: some View {
        @Bindable var vm = filterVM

        Map(position: $position) {
            if let location = locationManager.lastLocation {
                Annotation(String(localized: "map.myLocation"), coordinate: location) {
                    ZStack {
                        Circle()
                            .fill(.blue.opacity(0.15))
                            .frame(width: 36, height: 36)
                            .scaleEffect(pulseAnimation ? 1.4 : 1.0)
                            .opacity(pulseAnimation ? 0.0 : 0.15)
                            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: false), value: pulseAnimation)
                        Circle()
                            .fill(.blue)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(.white, lineWidth: 2.5))
                            .shadow(color: .blue.opacity(0.4), radius: 4)
                    }
                    .onAppear { pulseAnimation = true }
                }
            }

            ForEach(filtered) { restaurant in
                Annotation(restaurant.name, coordinate: restaurant.coordinate) {
                    mapPin(for: restaurant)
                        .onTapGesture {
                            selectedRestaurant = restaurant
                        }
                }
            }
        }
        .onMapCameraChange { context in
            let zoomed = context.region.span.latitudeDelta < 0.03
            if zoomed != isZoomedIn {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isZoomedIn = zoomed
                }
            }
        }
        .onTapGesture {
            searchFocused = false
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
                    matchCount: filtered.count,
                    onDismiss: { withAnimation { showRatingFilter = false } }
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // Bottom-right: location
        .overlay(alignment: .bottomTrailing) {
            MapControlButton(icon: "location.fill") {
                if locationManager.authorizationStatus == .notDetermined {
                    locationManager.requestPermission()
                } else if let location = locationManager.lastLocation {
                    withAnimation {
                        position = .region(MKCoordinateRegion(
                            center: location,
                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                        ))
                    }
                }
            }
            .padding(.trailing, 12)
            .padding(.bottom, 16)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.selection, trigger: selectedRestaurant)
        .sensoryFeedback(.impact(weight: .light), trigger: showRatingFilter)
        .sheet(item: $selectedRestaurant) { restaurant in
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
    }

    // MARK: - Top Overlay

    @ViewBuilder
    private var topOverlay: some View {
        @Bindable var vm = filterVM
        let showingSuggestions = !filterVM.searchText.isEmpty

        VStack(spacing: 8) {
            // Search card
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                    TextField(
                        String(format: String(localized: "search.restaurants"), store.restaurants.count),
                        text: $vm.searchText
                    )
                    .focused($searchFocused)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .onSubmit {
                        if let first = searchSuggestions.first {
                            selectSearchResult(first)
                        }
                    }
                    if showingSuggestions {
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                searchFocused = false
                                filterVM.searchText = ""
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                if showingSuggestions {
                    Divider().padding(.horizontal, 12)
                    let capped = Array(searchSuggestions.prefix(5))
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
                        VStack(spacing: 0) {
                            ForEach(Array(capped.enumerated()), id: \.element.id) { index, restaurant in
                                searchSuggestionRow(for: restaurant)
                                if index < capped.count - 1 {
                                    Divider().padding(.leading, 52)
                                }
                            }
                        }
                    }
                }
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 2)

            // Chip bar (hide when showing suggestions)
            if !showingSuggestions {
                chipBar
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .animation(.easeInOut(duration: 0.2), value: showingSuggestions)
    }

    // MARK: - Chip Bar

    private var chipBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                openNowChip
                ratingChip
                cuisineChip
                neighborhoodChip
                priceChip
                sortChip

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
                text: active ? "≥ \(filterVM.minimumRating.formattedRating)" : "Rating",
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

    private var neighborhoodChip: some View {
        let count = filterVM.selectedNeighborhoods.count
        let active = count > 0
        let label: String
        if count == 1, let n = filterVM.selectedNeighborhoods.first {
            label = n.displayName
        } else if active {
            label = String(localized: "filter.neighborhood") + " · \(count)"
        } else {
            label = String(localized: "filter.neighborhood")
        }

        return Menu {
            ForEach(Neighborhood.allCases) { hood in
                Button {
                    withAnimation { filterVM.selectedNeighborhoods.toggle(hood) }
                } label: {
                    if filterVM.selectedNeighborhoods.contains(hood) {
                        Label(hood.displayName, systemImage: "checkmark")
                    } else {
                        Text(hood.displayName)
                    }
                }
            }
        } label: {
            MapChip(icon: "mappin", text: label, isActive: active)
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

    private var sortChip: some View {
        let isNonDefault = filterVM.sortField != .mampfRating || filterVM.sortAscending

        return Menu {
            ForEach(SortField.allCases) { field in
                Button {
                    filterVM.selectSort(field)
                } label: {
                    Label {
                        Text(field.displayName)
                    } icon: {
                        if filterVM.sortField == field {
                            Image(systemName: field.supportsDirection
                                  ? (filterVM.sortAscending ? "chevron.up" : "chevron.down")
                                  : "checkmark")
                        }
                    }
                }
            }
        } label: {
            MapChip(icon: "arrow.up.arrow.down", text: filterVM.sortField.displayName, isActive: isNonDefault)
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
        guard !filterVM.searchText.isEmpty else { return [] }
        let query = filterVM.searchText
        return store.restaurants.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.cuisineType.displayName.localizedCaseInsensitiveContains(query)
                || $0.neighborhood.displayName.localizedCaseInsensitiveContains(query)
        }
    }

    private func selectSearchResult(_ restaurant: Restaurant) {
        withAnimation(.easeOut(duration: 0.2)) {
            searchFocused = false
            filterVM.searchText = ""
        }
        withAnimation {
            position = .region(MKCoordinateRegion(
                center: restaurant.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            selectedRestaurant = restaurant
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
                .shadow(color: color.opacity(0.5), radius: 4)
        } else {
            Circle()
                .fill(color)
                .frame(width: 14, height: 14)
                .shadow(color: color.opacity(0.4), radius: 4)
        }
    }

    private func annotationColor(for restaurant: Restaurant) -> Color {
        guard let rating = restaurant.personalRating else { return .ffMuted }
        return .ratingColor(for: rating)
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
