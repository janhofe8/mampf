import SwiftUI
import CoreLocation

struct RestaurantListView: View {
    @Environment(FilterViewModel.self) private var filterVM
    @Environment(RestaurantStore.self) private var store
    @Environment(LocationManager.self) private var locationManager

    private var filtered: [Restaurant] {
        let base = showFavoritesOnly ? store.favorites : store.restaurants
        return filterVM.apply(to: base, userLocation: locationManager.lastLocation, communityRatings: store.communityRatings)
    }

    @Namespace private var heroNamespace
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var viewMode: ViewMode = .cards
    @State private var showFavoritesOnly = false

    private let compactColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    // MARK: - Body

    var body: some View {
        ScrollView {
            if store.isLoading && store.restaurants.isEmpty {
                skeletonContent
            } else {
                activeFiltersBar

                switch viewMode {
                case .grid:
                    LazyVGrid(columns: compactColumns, spacing: 14) {
                        ForEach(filtered) { restaurant in
                            NavigationLink(value: restaurant) {
                                RestaurantCardView(
                                    restaurant: restaurant,
                                    isFavorite: store.isFavorite(restaurant),
                                    onFavoriteTap: { store.toggleFavorite(restaurant) },
                                    compact: true,
                                    communityRating: store.communityRating(for: restaurant)
                                )
                            }
                            .buttonStyle(.plain)
                            .matchedTransitionSource(id: restaurant.id, in: heroNamespace) { config in
                                config.clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .transition(.opacity)
                case .list:
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { restaurant in
                            NavigationLink(value: restaurant) {
                                listRow(for: restaurant)
                            }
                            .buttonStyle(.plain)
                            .matchedTransitionSource(id: restaurant.id, in: heroNamespace) { config in
                                config.clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            Divider().padding(.leading, 110)
                        }
                    }
                    .padding(.top, 8)
                    .transition(.opacity)
                case .cards:
                    LazyVStack(spacing: 16) {
                        ForEach(filtered) { restaurant in
                            NavigationLink(value: restaurant) {
                                RestaurantCardView(
                                    restaurant: restaurant,
                                    isFavorite: store.isFavorite(restaurant),
                                    onFavoriteTap: { store.toggleFavorite(restaurant) },
                                    communityRating: store.communityRating(for: restaurant),
                                    distanceText: distanceText(to: restaurant)
                                )
                            }
                            .buttonStyle(.plain)
                            .matchedTransitionSource(id: restaurant.id, in: heroNamespace) { config in
                                config.clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .transition(.opacity)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .searchable(text: $searchText, prompt: Text(String(format: String(localized: "search.restaurants"), store.restaurants.count)))
        .task(id: searchText) {
            if searchText.isEmpty {
                filterVM.activeSearchText = ""
                return
            }
            try? await Task.sleep(for: .milliseconds(250))
            filterVM.activeSearchText = searchText
        }
        .refreshable { await store.refresh() }
        .navigationTitle("")
        .toolbarTitleDisplayMode(.inline)
        .onAppear { applyBrandedNavBarAppearance() }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button {} label: {
                        Label("Hamburg", systemImage: "checkmark")
                    }
                    Section {
                        Button {} label: {
                            Label("city.comingSoon", systemImage: "clock")
                        }
                        .disabled(true)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Hamburg")
                            .font(.system(size: 22, weight: .bold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.primary)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showFavoritesOnly.toggle()
                    }
                } label: {
                    Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                        .foregroundStyle(showFavoritesOnly ? .red : .ffPrimary)
                }
                .accessibilityLabel(showFavoritesOnly ? "Show all" : "Show favorites")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewMode = viewMode.next
                    }
                } label: {
                    Image(systemName: viewModeIcon)
                        .foregroundStyle(.ffPrimary)
                }
                .accessibilityLabel("Change view mode")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
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
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundStyle(.ffPrimary)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingFilters = true
                } label: {
                    Image(systemName: filterVM.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundStyle(.ffPrimary)
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheetView()
        }
        .overlay {
            if filtered.isEmpty && !store.isLoading {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .navigationDestination(for: Restaurant.self) { restaurant in
            RestaurantDetailView(restaurant: restaurant)
                .navigationTransition(.zoom(sourceID: restaurant.id, in: heroNamespace))
        }
        .sensoryFeedback(.selection, trigger: viewMode)
        .sensoryFeedback(.impact(weight: .medium), trigger: showFavoritesOnly)
    }

    // MARK: - Active Filters Bar (#4 + #5)

    @ViewBuilder
    private var activeFiltersBar: some View {
        let isNonDefaultSort = filterVM.sortField != .mampfRating || filterVM.sortAscending

        if isNonDefaultSort || filterVM.hasActiveFilters {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    if isNonDefaultSort {
                        chipButton(
                            icon: filterVM.sortField.icon,
                            label: filterVM.sortField.displayName,
                            suffix: filterVM.sortField.supportsDirection
                                ? (filterVM.sortAscending ? "chevron.up" : "chevron.down")
                                : nil,
                            tinted: true
                        ) {
                            withAnimation {
                                filterVM.sortField = .mampfRating
                                filterVM.sortAscending = false
                            }
                        }
                    }

                    ForEach(filterVM.selectedCuisines.sorted(by: { $0.rawValue < $1.rawValue })) { cuisine in
                        removableChip(label: "\(cuisine.icon) \(cuisine.displayName)") {
                            withAnimation { filterVM.selectedCuisines.toggle(cuisine) }
                        }
                    }

                    ForEach(filterVM.selectedNeighborhoods.sorted(by: { $0.rawValue < $1.rawValue })) { hood in
                        removableChip(label: hood.displayName) {
                            withAnimation { filterVM.selectedNeighborhoods.toggle(hood) }
                        }
                    }

                    ForEach(filterVM.selectedPriceRanges.sorted(by: { $0.tier < $1.tier })) { price in
                        removableChip(label: price.label) {
                            withAnimation { filterVM.selectedPriceRanges.toggle(price) }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private func chipButton(icon: String, label: String, suffix: String?, tinted: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10, weight: .bold))
                Text(label)
                if let suffix {
                    Image(systemName: suffix).font(.system(size: 9, weight: .bold))
                }
                Image(systemName: "xmark").font(.system(size: 9, weight: .bold))
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tinted ? Color.ffPrimary.opacity(0.12) : Color(.tertiarySystemFill), in: Capsule())
            .foregroundStyle(tinted ? .ffPrimary : .primary)
        }
    }

    private func removableChip(label: String, onRemove: @escaping () -> Void) -> some View {
        Button(action: onRemove) {
            HStack(spacing: 4) {
                Text(label)
                Image(systemName: "xmark").font(.system(size: 9, weight: .bold))
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.tertiarySystemFill), in: Capsule())
            .foregroundStyle(.primary)
        }
    }

    // MARK: - List Row

    private func listRow(for restaurant: Restaurant) -> some View {
        HStack(alignment: .center, spacing: 14) {
            AsyncRestaurantImage(url: restaurant.imageUrl.flatMap(URL.init), cuisineIcon: restaurant.cuisineType.icon)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(restaurant.name)
                    .font(.system(size: 18, weight: .bold))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let personal = restaurant.personalRating {
                        RatingPill(icon: "star.fill", value: personal.formattedRating, color: RatingSource.personal.color, textColor: .white)
                    }
                    if let cr = store.communityRating(for: restaurant) {
                        RatingPill(icon: "person.2.fill", value: String(format: "%.1f", cr.average), color: RatingSource.community.color, textColor: .black)
                    } else {
                        RatingPill(icon: "person.2.fill", value: "–", color: Color.gray.opacity(0.2), textColor: .secondary)
                    }
                    if let google = restaurant.googleRating {
                        RatingPill(icon: "globe", value: String(format: "%.1f", google), color: RatingSource.google.color, textColor: .white)
                    }
                }

                HStack(spacing: 4) {
                    if restaurant.closingSoon, let min = restaurant.minutesUntilClosing {
                        Circle().fill(.orange).frame(width: 6, height: 6)
                        Text(String(format: String(localized: "status.closingSoon"), min))
                            .foregroundStyle(.orange)
                            .fontWeight(.semibold)
                    } else if let isOpen = restaurant.isOpenNow {
                        Circle()
                            .fill(isOpen ? .green : .red)
                            .frame(width: 6, height: 6)
                    }
                    Text("\(restaurant.neighborhood.displayName) · \(restaurant.cuisineType.icon) \(restaurant.cuisineType.displayName) · \(restaurant.priceRange.label)")
                    if let dist = distanceText(to: restaurant) {
                        Text("· \(dist)")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(listRowAccessibilityLabel(for: restaurant))
        .accessibilityAddTraits(.isButton)
    }

    private func listRowAccessibilityLabel(for restaurant: Restaurant) -> String {
        var parts = [restaurant.name, restaurant.cuisineType.displayName, restaurant.neighborhood.displayName]
        if let rating = restaurant.personalRating { parts.append("MAMPF \(rating.formattedRating)") }
        if let isOpen = restaurant.isOpenNow { parts.append(isOpen ? String(localized: "status.open") : String(localized: "status.closed")) }
        return parts.joined(separator: ", ")
    }

    // MARK: - Distance (#11)

    private func distanceText(to restaurant: Restaurant) -> String? {
        guard let loc = locationManager.lastLocation else { return nil }
        let from = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
        let to = CLLocation(latitude: restaurant.latitude, longitude: restaurant.longitude)
        let meters = from.distance(from: to)
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }

    // MARK: - Skeleton

    @ViewBuilder
    private var skeletonContent: some View {
        switch viewMode {
        case .cards:
            LazyVStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonCardView()
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        case .grid:
            LazyVGrid(columns: compactColumns, spacing: 14) {
                ForEach(0..<6, id: \.self) { _ in
                    SkeletonCardView(compact: true)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        case .list:
            LazyVStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { _ in
                    SkeletonListRow()
                    Divider().padding(.leading, 110)
                }
            }
            .padding(.top, 8)
        }
    }

    private var viewModeIcon: String {
        viewMode.icon
    }
}

enum ViewMode: CaseIterable {
    case cards, grid, list

    var icon: String {
        switch self {
        case .cards: "square.grid.2x2"
        case .grid: "list.bullet"
        case .list: "rectangle.grid.1x2"
        }
    }

    var next: ViewMode {
        let all = Self.allCases
        let idx = all.firstIndex(of: self)!
        return all[(idx + 1) % all.count]
    }
}

#Preview {
    NavigationStack {
        RestaurantListView()
    }
    .environment(FilterViewModel())
    .environment(RestaurantStore())
    .environment(LocationManager())
}
