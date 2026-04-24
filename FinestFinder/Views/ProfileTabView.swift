import SwiftUI

struct ProfileTabView: View {
    @Environment(AuthService.self) private var auth
    @Environment(RestaurantStore.self) private var store

    @State private var showingLogin = false
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    @State private var signupEmail: String = ""
    @State private var prefilledEmailForSheet: String?

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
        .navigationDestination(for: Restaurant.self) { restaurant in
            RestaurantDetailView(restaurant: restaurant)
        }
        .task(id: auth.currentUserId) {
            // Always load — anon users also have ratings via device_id.
            await store.loadAllMyRatings()
        }
        .onAppear {
            applyBrandedNavBarAppearance()
            Task { await store.loadAllMyRatings() }
        }
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
                if auth.isSignedIn {
                    signOutButton
                        .padding(.top, 12)
                }
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
            .padding(.vertical, 6)
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
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.ffPrimary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(auth.currentUserDisplayName ?? auth.currentUserEmail ?? "")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(auth.currentUserDisplayName != nil ? (auth.currentUserEmail ?? "") : String(localized: "profile.signedIn"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats

    private var statsCard: some View {
        let count = store.myRatingEntries.count
        let average: Double? = count > 0
            ? store.myRatingEntries.map(\.rating).reduce(0, +) / Double(count)
            : nil
        let favoriteCuisine = computeFavoriteCuisine()

        return HStack(spacing: 0) {
            statBox(
                value: "\(count)",
                label: String(localized: "profile.stats.rated")
            )
            Divider().frame(height: 36)
            statBox(
                value: average.map { String(format: "%.1f", $0) } ?? "–",
                label: String(localized: "profile.stats.avg")
            )
            Divider().frame(height: 36)
            statBox(
                value: favoriteCuisine?.icon ?? "–",
                label: favoriteCuisine?.displayName ?? String(localized: "profile.stats.favorite")
            )
        }
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .lineLimit(1)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func computeFavoriteCuisine() -> CuisineType? {
        guard !store.myRatingEntries.isEmpty else { return nil }
        let ratingsByCuisine: [CuisineType: [Double]] = Dictionary(
            grouping: store.myRatingEntries.compactMap { entry in
                store.restaurants.first(where: { $0.id == entry.restaurantId }).map { ($0.cuisineType, entry.rating) }
            },
            by: { $0.0 }
        ).mapValues { $0.map(\.1) }

        // Require at least 2 ratings in a cuisine to avoid one-hit favorites
        let qualifying = ratingsByCuisine.filter { $0.value.count >= 2 }
        let pool = qualifying.isEmpty ? ratingsByCuisine : qualifying
        return pool.max { a, b in
            let avgA = a.value.reduce(0, +) / Double(a.value.count)
            let avgB = b.value.reduce(0, +) / Double(b.value.count)
            return avgA < avgB
        }?.key
    }

    // MARK: - Ratings / Wishlist Sections

    private var ratedEntriesWithRestaurants: [(MyRatingEntry, Restaurant)] {
        store.myRatingEntries
            .compactMap { entry in
                store.restaurants.first(where: { $0.id == entry.restaurantId }).map { (entry, $0) }
            }
            .sorted { $0.0.updatedAt > $1.0.updatedAt }
    }

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
                        NavigationLink(value: pair.1) {
                            ratingRow(restaurant: pair.1, rating: pair.0.rating)
                        }
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
                .frame(height: CGFloat(ratedEntriesWithRestaurants.count) * 64)
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
                        NavigationLink(value: restaurant) {
                            wishlistRow(restaurant: restaurant)
                        }
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
                .frame(height: CGFloat(wantToTry.count) * 64)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func sectionHeader(_ titleKey: LocalizedStringKey, count: Int) -> some View {
        HStack {
            Text(titleKey)
                .font(.system(.headline, design: .rounded))
            if count > 0 {
                Text("\(count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func ratingRow(restaurant: Restaurant, rating: Double) -> some View {
        HStack(spacing: 12) {
            AsyncRestaurantImage(url: restaurant.imageUrl.flatMap(URL.init), cuisineIcon: restaurant.cuisineType.icon, targetSize: 44)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(restaurant.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("\(restaurant.cuisineType.icon) \(restaurant.cuisineType.displayName) · \(restaurant.neighborhood.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            RatingPill(
                icon: "star.fill",
                value: rating.formattedRating,
                color: RatingSource.community.color,
                textColor: .black,
                size: .compact
            )
        }
        .padding(.leading, 12)
        .padding(.trailing, 4)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private func wishlistRow(restaurant: Restaurant) -> some View {
        HStack(spacing: 12) {
            AsyncRestaurantImage(url: restaurant.imageUrl.flatMap(URL.init), cuisineIcon: restaurant.cuisineType.icon, targetSize: 44)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(restaurant.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("\(restaurant.cuisineType.icon) \(restaurant.cuisineType.displayName) · \(restaurant.neighborhood.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let personal = restaurant.personalRating {
                RatingPill(
                    icon: "star.fill",
                    value: personal.formattedRating,
                    color: RatingSource.personal.color,
                    textColor: .white,
                    size: .compact
                )
            }

        }
        .padding(.leading, 12)
        .padding(.trailing, 4)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
        Button(role: .destructive) {
            Task {
                try? await auth.signOut()
            }
        } label: {
            Text("profile.signOut")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    NavigationStack {
        ProfileTabView()
    }
    .environment(AuthService())
    .environment(RestaurantStore())
}
