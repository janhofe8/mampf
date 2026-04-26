import SwiftUI

struct ProfileTabView: View {
    @Environment(AuthService.self) private var auth
    @Environment(RestaurantStore.self) private var store
    @Environment(FilterViewModel.self) private var filterVM
    @Environment(TabRouter.self) private var tabRouter

    @State private var showingLogin = false
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    @State private var signupEmail: String = ""
    @State private var prefilledEmailForSheet: String?
    @State private var navigatedRestaurant: Restaurant?

    // Cached stats — recomputed only when ratings or restaurants change, not per render.
    @State private var ratedCount: Int = 0
    @State private var averageRating: Double?
    @State private var mampfsCount: Int = 0
    @State private var jansMampfsTotal: Int = 0
    @State private var topSpot: (Restaurant, Double)?
    @State private var stammviertel: Neighborhood?
    @State private var favoriteCuisine: CuisineType?
    @State private var ratedEntriesWithRestaurants: [(MyRatingEntry, Restaurant)] = []

    var body: some View {
        profileContent
            .navigationTitle("tab.profile")
            .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.ffPrimary)
                }
                .accessibilityLabel("settings.title")
            }
        }
        .sheet(isPresented: $showingLogin) {
            LoginSheetView(prefilledEmail: prefilledEmailForSheet)
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(isPresented: $showingEditProfile) { EditProfileView() }
        .navigationDestination(item: $navigatedRestaurant) { restaurant in
            RestaurantDetailView(restaurant: restaurant)
        }
        .task(id: auth.currentUserId) {
            // Always load — anon users also have ratings via device_id.
            await store.loadAllMyRatings()
        }
        .onAppear {
            applyBrandedNavBarAppearance()
            recomputeStats()
        }
        .onChange(of: store.myRatingEntries) { recomputeStats() }
        .onChange(of: store.restaurants.count) { recomputeStats() }
    }

    // MARK: - Profile Content (same for anon + signed-in, only the top header differs)

    private var profileContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                if auth.isSignedIn {
                    accountHeader
                } else {
                    signInBanner
                }
                statsCard
                ratingsSection
                wantToTrySection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .refreshable {
            await store.loadAllMyRatings()
        }
    }

    /// Inline email entry above the real profile data — converts better than a link.
    private var signInBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("profile.syncBanner.title")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                Text("profile.syncBanner.subtitle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Image(systemName: "envelope")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ZStack(alignment: .leading) {
                    if signupEmail.isEmpty {
                        Text("login.emailPlaceholder")
                            .font(.subheadline)
                            .foregroundStyle(Color(.systemGray3))
                            .allowsHitTesting(false)
                    }
                    TextField("", text: $signupEmail)
                        .font(.subheadline)
                        .tint(.ffPrimary)
                }
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .onSubmit(continueWithEmail)
                Button(action: continueWithEmail) {
                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            signupEmail.contains("@") ? Color.ffPrimary : Color.gray.opacity(0.35),
                            in: Circle()
                        )
                }
                .disabled(!signupEmail.contains("@"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func continueWithEmail() {
        let trimmed = signupEmail.trimmingCharacters(in: .whitespaces)
        prefilledEmailForSheet = trimmed.contains("@") ? trimmed : nil
        showingLogin = true
    }

    private var accountHeader: some View {
        Button {
            showingEditProfile = true
        } label: {
            HStack(spacing: 14) {
                Circle()
                    .fill(Color.ffPrimary)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Text(userInitial)
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(auth.currentUserDisplayName ?? auth.currentUserEmail ?? "")
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("profile.editProfile")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var userInitial: String {
        let trimmedName = auth.currentUserDisplayName?.trimmingCharacters(in: .whitespaces) ?? ""
        let source: String
        if !trimmedName.isEmpty {
            source = trimmedName
        } else if let email = auth.currentUserEmail, let local = email.split(separator: "@").first {
            source = String(local)
        } else {
            source = "?"
        }
        return source.first.map { String($0).uppercased() } ?? "?"
    }

    // MARK: - Stats

    private var statsCard: some View {
        ZStack {
            statsContent
                .blur(radius: auth.isSignedIn ? 0 : 8)
                .allowsHitTesting(auth.isSignedIn)
            if !auth.isSignedIn {
                lockedStatsOverlay
            }
        }
    }

    private var statsContent: some View {
        VStack(spacing: 6) {
            Button {
                if let r = topSpot?.0 { navigatedRestaurant = r }
            } label: {
                topSpotWideTile
            }
            .buttonStyle(StatTileButtonStyle())
            .disabled(topSpot == nil)
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)],
                spacing: 6
            ) {
                Button { openMyRatingsOnMap() } label: {
                    statTile(
                        icon: "map",
                        value: auth.isSignedIn ? exploredPercentText : "8 %",
                        label: String(localized: "profile.stats.explored")
                    )
                }
                .buttonStyle(StatTileButtonStyle())
                .disabled(store.myRatings.isEmpty)
                Button { openJansMampfsOnMap() } label: {
                    statTile(
                        icon: "star.fill",
                        value: auth.isSignedIn ? "\(mampfsCount)/\(jansMampfsTotal)" : "5/27",
                        label: String(localized: "profile.stats.mampfs")
                    )
                }
                .buttonStyle(StatTileButtonStyle())
                Button { openStammviertelOnMap() } label: {
                    statTile(
                        icon: "mappin.and.ellipse",
                        value: auth.isSignedIn ? (stammviertel?.displayName ?? "–") : "Ottensen",
                        label: String(localized: "profile.stats.stammviertel")
                    )
                }
                .buttonStyle(StatTileButtonStyle())
                .disabled(stammviertel == nil)
                Button { openFavoriteCuisineOnMap() } label: {
                    cuisineStatTile()
                }
                .buttonStyle(StatTileButtonStyle())
                .disabled(favoriteCuisine == nil)
            }
        }
    }

    private var topSpotWideTile: some View {
        let hasData = auth.isSignedIn ? topSpot != nil : true
        let name = auth.isSignedIn ? (topSpot?.0.name ?? "–") : "Lokmam"
        let rating = auth.isSignedIn ? (topSpot?.1 ?? 0) : 9.5
        let url = auth.isSignedIn ? topSpot?.0.imageUrl.flatMap(URL.init) : nil
        let cuisineIcon = auth.isSignedIn ? (topSpot?.0.cuisineType.icon ?? "🍽") : "🍕"

        return HStack(spacing: 10) {
            AsyncRestaurantImage(url: url, cuisineIcon: cuisineIcon, cornerRadius: 9, targetSize: 56)
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .lineLimit(1)
                Text("profile.stats.topSpot")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            if hasData {
                RatingPill(
                    icon: "star.fill",
                    value: rating.formattedRating,
                    color: Color.ratingColor(for: rating),
                    textColor: Color.ratingTextColor(for: rating),
                    size: .small
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ffPrimary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    private func statTile(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.ffPrimary)
                .frame(width: 36, height: 36)
                .background(Color.ffPrimary.opacity(0.14), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .lineLimit(1)
                Text(label)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ffPrimary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    private func cuisineStatTile() -> some View {
        let emoji = auth.isSignedIn ? (favoriteCuisine?.icon ?? "🍽") : "🍝"
        let cuisineName = auth.isSignedIn
            ? (favoriteCuisine?.displayName ?? "–")
            : String(localized: "cuisine.italian")

        return HStack(spacing: 10) {
            Text(emoji)
                .font(.system(size: 20))
                .frame(width: 36, height: 36)
                .background(Color.ffPrimary.opacity(0.14), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 1) {
                Text(cuisineName)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .lineLimit(1)
                Text("profile.stats.favorite")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ffPrimary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    private func openMyRatingsOnMap() {
        guard !store.myRatings.isEmpty else { return }
        filterVM.clearFilters()
        filterVM.showMyRatedOnly = true
        tabRouter.selected = .map
    }

    private func openJansMampfsOnMap() {
        filterVM.clearFilters()
        filterVM.minimumRating = 9
        tabRouter.selected = .map
    }

    private func openStammviertelOnMap() {
        guard let hood = stammviertel else { return }
        filterVM.clearFilters()
        filterVM.selectedNeighborhoods = [hood]
        tabRouter.selected = .map
    }

    private func openFavoriteCuisineOnMap() {
        guard let cuisine = favoriteCuisine else { return }
        filterVM.clearFilters()
        filterVM.selectedCuisines = [cuisine]
        tabRouter.selected = .map
    }

    private var exploredPercentText: String {
        let total = store.restaurants.count
        guard total > 0 else { return "–" }
        let pct = Int((Double(ratedCount) / Double(total) * 100).rounded())
        return "\(pct) %"
    }

    private var lockedStatsOverlay: some View {
        Button {
            let trimmed = signupEmail.trimmingCharacters(in: .whitespaces)
            prefilledEmailForSheet = trimmed.contains("@") ? trimmed : nil
            showingLogin = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text("profile.stats.locked")
                    .font(.footnote.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.ffPrimary, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    /// Recomputes derived stats once when source data changes, instead of per render.
    /// Uses `store.restaurantsById` for O(1) joins instead of repeated `first(where:)` scans.
    private func recomputeStats() {
        let entries = store.myRatingEntries
        ratedCount = entries.count
        averageRating = entries.isEmpty ? nil : entries.map(\.rating).reduce(0, +) / Double(entries.count)

        // Join entries with restaurants in O(n) via the lookup dict.
        let pairs = entries.compactMap { entry -> (MyRatingEntry, Restaurant)? in
            store.restaurant(id: entry.restaurantId).map { (entry, $0) }
        }
        ratedEntriesWithRestaurants = pairs.sorted { $0.0.updatedAt > $1.0.updatedAt }

        // Favorite cuisine: average rating per cuisine, prefer cuisines with ≥2 ratings.
        let byCuisine = Dictionary(grouping: pairs, by: { $0.1.cuisineType })
            .mapValues { $0.map(\.0.rating) }
        let qualifying = byCuisine.filter { $0.value.count >= 2 }
        let pool = qualifying.isEmpty ? byCuisine : qualifying
        favoriteCuisine = pool.max { a, b in
            let avgA = a.value.reduce(0, +) / Double(a.value.count)
            let avgB = b.value.reduce(0, +) / Double(b.value.count)
            return avgA < avgB
        }?.key

        // MAMPFs entdeckt = how many of Jan's top picks (personalRating ≥ 9) the user has visited.
        // "Visited" = user has rated the spot. Y = total Jan-MAMPFs in the DB.
        let jansMampfs = store.restaurants.filter { ($0.personalRating ?? 0) >= 9 }
        jansMampfsTotal = jansMampfs.count
        mampfsCount = jansMampfs.filter { store.myRatings[$0.id] != nil }.count

        // Top spot: highest rating, tie-break by most recent.
        topSpot = pairs
            .max { lhs, rhs in
                if lhs.0.rating != rhs.0.rating { return lhs.0.rating < rhs.0.rating }
                return lhs.0.updatedAt < rhs.0.updatedAt
            }
            .map { ($0.1, $0.0.rating) }

        // Stammviertel: neighborhood with the most ratings.
        let counts = Dictionary(grouping: pairs, by: { $0.1.neighborhood }).mapValues(\.count)
        stammviertel = counts.max { $0.value < $1.value }?.key
    }

    // MARK: - Ratings / Wishlist Sections

    /// Favorites that the user has rated → "Visited"
    private var visitedFavorites: [Restaurant] {
        store.favorites.filter { store.myRatings[$0.id] != nil }
    }

    /// Favorites without own rating → "Want to try"
    private var wantToTry: [Restaurant] {
        store.favorites.filter { store.myRatings[$0.id] == nil }
    }

    @ViewBuilder
    private var ratingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("profile.yourRatings", count: ratedEntriesWithRestaurants.count)

            if ratedEntriesWithRestaurants.isEmpty {
                EmptyStateView(
                    icon: "star.bubble",
                    title: "empty.ratings.title",
                    message: "empty.ratings.message",
                    compact: true
                )
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
            } else {
                // Native List → gives us `.swipeActions`. Scroll disabled so the
                // outer ScrollView keeps scrolling vertically; only horizontal swipes activate.
                List {
                    ForEach(ratedEntriesWithRestaurants, id: \.0.id) { pair in
                        Button {
                            navigatedRestaurant = pair.1
                        } label: {
                            ratingRow(restaurant: pair.1, rating: pair.0.rating)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color(.secondarySystemBackground))
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 60 }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await store.deleteRating(for: pair.1) }
                            } label: {
                                Label(String(localized: "detail.remove"), systemImage: "trash.fill")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollDisabled(true)
                .frame(height: CGFloat(ratedEntriesWithRestaurants.count) * 76)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    @ViewBuilder
    private var wantToTrySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("profile.wantToTry", count: wantToTry.count)

            if wantToTry.isEmpty {
                EmptyStateView(
                    icon: "heart.circle",
                    title: "empty.wantToTry.title",
                    message: "empty.wantToTry.message",
                    compact: true
                )
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
            } else {
                List {
                    ForEach(wantToTry, id: \.id) { restaurant in
                        Button {
                            navigatedRestaurant = restaurant
                        } label: {
                            wishlistRow(restaurant: restaurant)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color(.secondarySystemBackground))
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 60 }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.toggleFavorite(restaurant)
                            } label: {
                                Label(String(localized: "a11y.removeFavorite"), systemImage: "heart.slash.fill")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollDisabled(true)
                .frame(height: CGFloat(wantToTry.count) * 76)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func sectionHeader(_ titleKey: LocalizedStringKey, count: Int) -> some View {
        HStack(spacing: 8) {
            Text(titleKey)
                .font(.system(.title3, design: .rounded).weight(.heavy))
            if count > 0 {
                Text("\(count)")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(.ffPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.ffPrimary.opacity(0.14), in: Capsule())
            }
            Spacer()
        }
    }

    private func ratingRow(restaurant: Restaurant, rating: Double) -> some View {
        HStack(alignment: .center, spacing: 12) {
            AsyncRestaurantImage(url: restaurant.imageUrl.flatMap(URL.init), cuisineIcon: restaurant.cuisineType.icon, targetSize: 56)
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(restaurant.name)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .lineLimit(1)
                Text("\(restaurant.cuisineType.icon) \(restaurant.cuisineType.displayName) · \(restaurant.neighborhood.displayName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            RatingPill(
                icon: "star.fill",
                value: rating.formattedRating,
                color: Color.ratingColor(for: rating),
                textColor: Color.ratingTextColor(for: rating),
                size: .small
            )

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.leading, 12)
        .padding(.trailing, 12)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func wishlistRow(restaurant: Restaurant) -> some View {
        HStack(alignment: .center, spacing: 12) {
            AsyncRestaurantImage(url: restaurant.imageUrl.flatMap(URL.init), cuisineIcon: restaurant.cuisineType.icon, targetSize: 56)
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(restaurant.name)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .lineLimit(1)
                Text("\(restaurant.cuisineType.icon) \(restaurant.cuisineType.displayName) · \(restaurant.neighborhood.displayName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let personal = restaurant.personalRating {
                RatingPill(
                    icon: "star.fill",
                    value: personal.formattedRating,
                    color: Color.ratingColor(for: personal),
                    textColor: Color.ratingTextColor(for: personal),
                    size: .small
                )
            }

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.leading, 12)
        .padding(.trailing, 12)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

}

private struct StatTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        ProfileTabView()
    }
    .environment(AuthService())
    .environment(RestaurantStore())
}
