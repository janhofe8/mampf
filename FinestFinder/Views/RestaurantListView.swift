import SwiftUI
import CoreLocation

struct RestaurantListView: View {
    @Environment(FilterViewModel.self) private var filterVM
    @Environment(RestaurantStore.self) private var store
    @Environment(LocationManager.self) private var locationManager

    @Namespace private var heroNamespace
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var viewMode: ViewMode = .cards
    @State private var showFavoritesOnly = false
    @State private var filtered: [Restaurant] = []
    @State private var isHeaderVisible: Bool = true
    @State private var scrollAccumulator: CGFloat = 0
    @FocusState private var searchFocused: Bool

    private var showingDropdown: Bool { searchFocused || !searchText.isEmpty }
    private var headerVisible: Bool { isHeaderVisible || showingDropdown }

    /// Hash of all inputs that affect `filtered` — single onChange instead of many
    private var filterInputsToken: Int {
        var h = Hasher()
        h.combine(store.restaurants.count)
        h.combine(store.communityRatings.count)
        h.combine(showFavoritesOnly)
        h.combine(filterVM.activeSearchText)
        h.combine(filterVM.selectedCuisines)
        h.combine(filterVM.selectedNeighborhoods)
        h.combine(filterVM.selectedPriceRanges)
        h.combine(filterVM.minimumRating)
        h.combine(filterVM.showOpenOnly)
        h.combine(filterVM.sortField)
        h.combine(filterVM.sortAscending)
        return h.finalize()
    }

    private func refreshFiltered() {
        let base = showFavoritesOnly ? store.favorites : store.restaurants
        filtered = filterVM.apply(to: base, userLocation: locationManager.lastLocation, communityRatings: store.communityRatings)
    }

    private let compactColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    // MARK: - Body

    var body: some View {
        Group {
            if showingDropdown {
                VStack(spacing: 0) {
                    searchHeader
                    Spacer(minLength: 0)
                }
            } else {
                scrollContent
                    .safeAreaInset(edge: .top, spacing: 0) {
                        if headerVisible {
                            VStack(spacing: 0) {
                                searchHeader
                                activeFiltersBar
                            }
                            .background(Color(.systemBackground))
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
            }
        }
        .task(id: searchText) {
            if searchText.isEmpty {
                filterVM.activeSearchText = ""
                return
            }
            try? await Task.sleep(for: .milliseconds(250))
            filterVM.activeSearchText = searchText
        }
        .task { refreshFiltered() }
        .onChange(of: filterInputsToken) { refreshFiltered() }
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
                .accessibilityLabel(String(localized: showFavoritesOnly ? "a11y.showAll" : "a11y.showFavorites"))
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewMode = viewMode.next
                    }
                } label: {
                    Image(systemName: viewModeIcon)
                        .font(.system(size: 17))
                        .frame(width: 22)
                        .foregroundStyle(.ffPrimary)
                }
                .accessibilityLabel(String(localized: "a11y.changeViewMode"))
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

    // MARK: - Search Header

    @ViewBuilder
    private var searchHeader: some View {
        VStack(spacing: 0) {
            searchBarRow
            if showingDropdown {
                Divider().padding(.horizontal, 12)
                searchDropdownContent
            }
        }
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
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
                    openSuggestion(first)
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
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var searchDropdownContent: some View {
        if searchText.isEmpty {
            categorySuggestions
        } else {
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

    private func searchSuggestionRow(for restaurant: Restaurant) -> some View {
        NavigationLink(value: restaurant) {
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
                        Text(restaurant.cuisineType.icon).font(.system(size: 11))
                        Text(restaurant.neighborhood.displayName)
                            .font(.caption).foregroundStyle(.secondary)
                        Text("·").font(.caption).foregroundStyle(.tertiary)
                        Text(restaurant.priceRange.label)
                            .font(.caption).foregroundStyle(.secondary)
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
        .simultaneousGesture(TapGesture().onEnded { clearSearch() })
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

    private func openSuggestion(_ restaurant: Restaurant) {
        // Onsubmit keyboard path — rely on NavigationLink in dropdown for push.
        // Here we just close search; user taps the row to navigate.
        clearSearch()
    }

    private func clearSearch() {
        withAnimation(.easeOut(duration: 0.2)) {
            searchFocused = false
            searchText = ""
            filterVM.activeSearchText = ""
        }
    }

    // MARK: - Scroll Content

    @ViewBuilder
    private var scrollContent: some View {
        ScrollView {
            if store.isLoading && store.restaurants.isEmpty {
                skeletonContent
            } else {
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
        .refreshable { await store.refresh() }
        .onScrollGeometryChange(for: CGFloat.self) { geo in
            geo.contentOffset.y
        } action: { oldValue, newValue in
            handleScrollChange(from: oldValue, to: newValue)
        }
    }

    private func handleScrollChange(from oldValue: CGFloat, to newValue: CGFloat) {
        // Always show near the top
        if newValue < 20 {
            if !isHeaderVisible {
                withAnimation(.easeOut(duration: 0.22)) { isHeaderVisible = true }
            }
            scrollAccumulator = 0
            return
        }

        let delta = newValue - oldValue
        // Reset accumulator on direction change
        if (delta > 0) != (scrollAccumulator > 0) {
            scrollAccumulator = 0
        }
        scrollAccumulator += delta

        if scrollAccumulator > 40, isHeaderVisible {
            withAnimation(.easeOut(duration: 0.22)) { isHeaderVisible = false }
            scrollAccumulator = 0
        } else if scrollAccumulator < -30, !isHeaderVisible {
            withAnimation(.easeOut(duration: 0.22)) { isHeaderVisible = true }
            scrollAccumulator = 0
        }
    }

    // MARK: - Active Filters Bar

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
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tinted ? Color.ffPrimary.opacity(0.12) : Color(.tertiarySystemFill), in: Capsule())
            .foregroundStyle(tinted ? .ffPrimary : .primary)
        }
        .buttonStyle(.borderless)
    }

    private func removableChip(label: String, onRemove: @escaping () -> Void) -> some View {
        Button(action: onRemove) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.ffPrimary.opacity(0.12), in: Capsule())
                .foregroundStyle(.ffPrimary)
        }
        .buttonStyle(.borderless)
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
        .contentShape(Rectangle())
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
