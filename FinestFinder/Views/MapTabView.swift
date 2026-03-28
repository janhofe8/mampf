import SwiftUI
import MapKit

struct MapTabView: View {
    @Environment(FilterViewModel.self) private var filterVM
    @Environment(RestaurantStore.self) private var store
    @State private var selectedRestaurant: Restaurant?
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 53.5575, longitude: 9.9620),
            span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
        )
    )
    @State private var isZoomedIn = false
    @State private var showingFilters = false
    @State private var showRatingFilter = false
    @State private var showSearch = false
    @FocusState private var searchFocused: Bool
    @State private var pulseAnimation = false
    @Environment(LocationManager.self) private var locationManager

    private var filtered: [Restaurant] {
        filterVM.apply(to: store.restaurants, userLocation: locationManager.lastLocation, communityRatings: store.communityRatings)
    }

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
            if showSearch {
                searchFocused = false
                if filterVM.searchText.isEmpty {
                    showSearch = false
                }
            }
            if showRatingFilter {
                showRatingFilter = false
            }
        }
        // Rating histogram overlay
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
        // Buttons top-right
        .overlay(alignment: .topTrailing) {
            VStack(spacing: 8) {
                MapControlButton(icon: "magnifyingglass") {
                    withAnimation {
                        showSearch.toggle()
                        if showSearch { searchFocused = true }
                        else { filterVM.searchText = "" }
                    }
                }
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
                MapControlButton(icon: showRatingFilter ? "star.fill" : "star") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showRatingFilter.toggle()
                    }
                }
                MapControlButton(icon: filterVM.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle") {
                    showingFilters = true
                }
                if filterVM.hasActiveFilters {
                    MapControlButton(icon: "xmark", tint: .ffWeak) {
                        withAnimation { filterVM.clearFilters() }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.top, 8)
            .padding(.trailing, 12)
        }
        .overlay(alignment: .top) {
            if showSearch { searchOverlay }
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheetView()
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.selection, trigger: selectedRestaurant)
        .sensoryFeedback(.impact(weight: .light), trigger: showSearch)
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

    @ViewBuilder
    private var searchOverlay: some View {
        @Bindable var vm = filterVM

        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(String(format: String(localized: "search.restaurants"), store.restaurants.count), text: $vm.searchText)
                    .focused($searchFocused)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        if let first = searchSuggestions.first {
                            selectSearchResult(first)
                        }
                    }
                if !filterVM.searchText.isEmpty {
                    Button {
                        filterVM.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: filterVM.searchText.isEmpty ? 12 : 0))
            .clipShape(.rect(topLeadingRadius: 12, topTrailingRadius: 12))

            if !filterVM.searchText.isEmpty {
                Divider().padding(.horizontal, 8)
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(searchSuggestions) { restaurant in
                            searchSuggestionRow(for: restaurant)
                        }
                        if searchSuggestions.isEmpty {
                            Text("search.noResults")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 12)
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxHeight: 240)
                .background(.regularMaterial)
                .clipShape(.rect(bottomLeadingRadius: 12, bottomTrailingRadius: 12))
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 64)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func searchSuggestionRow(for restaurant: Restaurant) -> some View {
        Button {
            selectSearchResult(restaurant)
        } label: {
            HStack(spacing: 8) {
                Text(restaurant.cuisineType.icon)
                    .font(.system(size: 16))
                Text(restaurant.name)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer()
                Text(restaurant.neighborhood.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(restaurant.priceRange.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
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
        searchFocused = false
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
