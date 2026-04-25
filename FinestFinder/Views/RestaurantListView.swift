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
    @State private var placeholder = RotatingPlaceholder(examples: [
        String(localized: "search.placeholder.pasta"),
        String(localized: "search.placeholder.ottensen"),
        String(localized: "search.placeholder.nine"),
        String(localized: "search.placeholder.ramen"),
        String(localized: "search.placeholder.pizza")
    ])
    @State private var showFavoritesOnly = false
    @State private var filtered: [Restaurant] = []
    @State private var suggestions: [Restaurant] = []
    @State private var distanceCache: [UUID: String] = [:]
    @State private var isHeaderVisible: Bool = true
    /// Plain class so its mutations during scroll don't invalidate the view body — vital
    /// for scroll smoothness. Only `isHeaderVisible` (a @State Bool) drives the actual UI.
    @State private var scrollTracker = ScrollTracker()
    @FocusState private var searchFocused: Bool

    private var showingDropdown: Bool { !searchText.isEmpty }
    /// Force-show when search dropdown is open so users keep access to the search field.
    private var headerVisible: Bool { isHeaderVisible || showingDropdown }

    /// Plain class for the scroll accumulator: mutating its property doesn't invalidate the view
    /// body (which @State on a CGFloat would). The only @State we touch on threshold-cross is
    /// `isHeaderVisible`, which has to invalidate to drive the safeAreaInset animation.
    private final class ScrollTracker {
        var accumulator: CGFloat = 0
    }

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

    /// Ranks restaurants against a free-text query.
    /// Name prefix > name contains > cuisine > neighborhood. Ties break on rating.
    static func rankMatches(_ query: String, in restaurants: [Restaurant]) -> [Restaurant] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }

        let scored: [(Restaurant, Int)] = restaurants.compactMap { r in
            let name = r.name.lowercased()
            let cuisine = r.cuisineType.displayName.lowercased()
            let hood = r.neighborhood.displayName.lowercased()

            let score: Int
            if name.hasPrefix(q) { score = 100 }
            else if name.contains(q) { score = 80 }
            else if cuisine.hasPrefix(q) { score = 60 }
            else if cuisine.contains(q) { score = 40 }
            else if hood.hasPrefix(q) { score = 30 }
            else if hood.contains(q) { score = 20 }
            else { return nil }

            return (r, score)
        }

        return scored
            .sorted { a, b in
                if a.1 != b.1 { return a.1 > b.1 }
                return (a.0.personalRating ?? 0) > (b.0.personalRating ?? 0)
            }
            .map(\.0)
    }

    // MARK: - Body

    var body: some View {
        scrollContent
            .safeAreaInset(edge: .top, spacing: 0) {
                headerContent
                    .frame(height: headerVisible ? nil : 0, alignment: .top)
                    .clipped()
                    .animation(.easeOut(duration: 0.2), value: headerVisible)
            }
        .task(id: searchText) {
            refreshSuggestions()
            if searchText.isEmpty {
                filterVM.activeSearchText = ""
                return
            }
            try? await Task.sleep(for: .milliseconds(250))
            filterVM.activeSearchText = searchText
        }
        // initial:true covers first appearance — re-appearing the view (e.g. zooming back from
        // detail) does NOT re-fire these. A standalone `.task { ... }` would, which previously
        // re-filtered all 155 restaurants on every back-nav and stalled the hero zoom animation.
        .onChange(of: filterInputsToken, initial: true) { refreshFiltered() }
        .onChange(of: store.restaurants.count, initial: true) {
            refreshSuggestions()
            refreshDistances()
        }
        .onChange(of: locationManager.lastLocationToken) { refreshDistances() }
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
                            .font(.system(size: 22, weight: .bold, design: .rounded))
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

        }
        .overlay {
            if filtered.isEmpty && !store.isLoading && !store.restaurants.isEmpty {
                emptyStateOverlay
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheetView()
        }
        .navigationDestination(for: Restaurant.self) { restaurant in
            RestaurantDetailView(restaurant: restaurant)
                .navigationTransition(.zoom(sourceID: restaurant.id, in: heroNamespace))
        }
        .sensoryFeedback(.selection, trigger: viewMode)
        .sensoryFeedback(.impact(weight: .medium), trigger: showFavoritesOnly)
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateOverlay: some View {
        if showFavoritesOnly && store.favorites.isEmpty {
            EmptyStateView(
                icon: "heart",
                title: "empty.favorites.title",
                message: "empty.favorites.message",
                actionTitle: "empty.favorites.cta",
                action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showFavoritesOnly = false
                    }
                }
            )
        } else if !searchText.isEmpty {
            EmptyStateView(
                icon: "magnifyingglass",
                title: "empty.noResults.title",
                message: "empty.noResults.message"
            )
        } else if filterVM.hasActiveFilters {
            EmptyStateView(
                icon: "line.3.horizontal.decrease.circle",
                title: "empty.noResults.title",
                message: "empty.noResults.message",
                actionTitle: "empty.noResults.cta",
                action: {
                    withAnimation { filterVM.clearFilters() }
                }
            )
        }
    }

    // MARK: - Search Header

    @ViewBuilder
    private var headerContent: some View {
        VStack(spacing: 0) {
            searchHeader
            if !showingDropdown {
                chipBar
            }
        }
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private var searchHeader: some View {
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
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var searchBarRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)
            ZStack(alignment: .leading) {
                if searchText.isEmpty {
                    Text(placeholder.current)
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
                            openSuggestion(first)
                        }
                    }
                    .onAppear {
                        if searchText.isEmpty && !searchFocused { placeholder.start() }
                    }
                    .onChange(of: searchFocused) {
                        searchFocused ? placeholder.stop() : placeholder.start()
                    }
                    .onChange(of: searchText) {
                        searchText.isEmpty ? placeholder.start() : placeholder.stop()
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

    private func searchSuggestionRow(for restaurant: Restaurant) -> some View {
        NavigationLink(value: restaurant) {
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

    private func refreshSuggestions() {
        guard !searchText.isEmpty else {
            if !suggestions.isEmpty { suggestions = [] }
            return
        }
        suggestions = Self.rankMatches(searchText, in: store.restaurants)
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
        Group {
            if store.isLoading && store.restaurants.isEmpty {
                ScrollView { skeletonContent }
            } else if viewMode == .list {
                listModeList
            } else {
                cardsOrGridScrollView
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
        if newValue < 20 {
            if !isHeaderVisible {
                withAnimation(.easeOut(duration: 0.22)) { isHeaderVisible = true }
            }
            scrollTracker.accumulator = 0
            return
        }
        let delta = newValue - oldValue
        if (delta > 0) != (scrollTracker.accumulator > 0) {
            scrollTracker.accumulator = 0
        }
        scrollTracker.accumulator += delta
        if scrollTracker.accumulator > 40, isHeaderVisible {
            withAnimation(.easeOut(duration: 0.22)) { isHeaderVisible = false }
            scrollTracker.accumulator = 0
        } else if scrollTracker.accumulator < -30, !isHeaderVisible {
            withAnimation(.easeOut(duration: 0.22)) { isHeaderVisible = true }
            scrollTracker.accumulator = 0
        }
    }

    private var cardsOrGridScrollView: some View {
        ScrollView {
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
            case .list:
                EmptyView()
            }
        }
    }

    /// List-mode uses a real SwiftUI List so we get native .swipeActions.
    private var listModeList: some View {
        List {
            ForEach(filtered) { restaurant in
                NavigationLink(value: restaurant) {
                    listRow(for: restaurant)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color(.systemBackground))
                .alignmentGuide(.listRowSeparatorLeading) { _ in 110 }
                .matchedTransitionSource(id: restaurant.id, in: heroNamespace) { config in
                    config.clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        store.toggleFavorite(restaurant)
                    } label: {
                        Label(
                            store.isFavorite(restaurant)
                                ? String(localized: "a11y.removeFavorite")
                                : String(localized: "a11y.addFavorite"),
                            systemImage: store.isFavorite(restaurant) ? "heart.slash.fill" : "heart.fill"
                        )
                    }
                    .tint(.red)
                }
            }
        }
        .listStyle(.plain)
        .transition(.opacity)
    }


    // MARK: - Chip Bar

    private var chipBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filtersChip
                sortChip
                openNowChip
                cuisineChip
                priceChip
                neighborhoodChip
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .sensoryFeedback(.selection, trigger: filterVM.selectedCuisines)
        .sensoryFeedback(.selection, trigger: filterVM.selectedNeighborhoods)
        .sensoryFeedback(.selection, trigger: filterVM.selectedPriceRanges)
    }

    private var filtersChip: some View {
        FiltersEntryChip(activeCount: filterVM.activeFilterCount) {
            showingFilters = true
        }
    }

    private var sortChip: some View {
        let isNonDefault = filterVM.sortField != .mampfRating || filterVM.sortAscending
        // Leading icon doubles as direction indicator — no second arrow in the text.
        let sortIcon: String = filterVM.sortField.supportsDirection
            ? (filterVM.sortAscending ? "arrow.up" : "arrow.down")
            : "shuffle"
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
            FilterBarChip(
                icon: sortIcon,
                text: filterVM.sortField.displayName,
                isActive: isNonDefault
            )
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
            FilterBarChip(icon: "mappin", text: label, isActive: active)
        }
    }

    // MARK: - List Row

    private func listRow(for restaurant: Restaurant) -> some View {
        HStack(alignment: .center, spacing: 14) {
            AsyncRestaurantImage(url: restaurant.imageUrl.flatMap(URL.init), cuisineIcon: restaurant.cuisineType.icon, targetSize: 80)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(restaurant.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
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
        distanceCache[restaurant.id]
    }

    /// Computes distance strings once per location/data change — avoids per-row recomputation while scrolling.
    private func refreshDistances() {
        guard let loc = locationManager.lastLocation else {
            if !distanceCache.isEmpty { distanceCache = [:] }
            return
        }
        let from = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
        var cache: [UUID: String] = [:]
        cache.reserveCapacity(store.restaurants.count)
        for restaurant in store.restaurants {
            let to = CLLocation(latitude: restaurant.latitude, longitude: restaurant.longitude)
            let meters = from.distance(from: to)
            cache[restaurant.id] = meters < 1000
                ? String(format: "%.0f m", meters)
                : String(format: "%.1f km", meters / 1000)
        }
        distanceCache = cache
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
