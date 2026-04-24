import SwiftUI

struct ProfileTabView: View {
    @Environment(AuthService.self) private var auth
    @Environment(RestaurantStore.self) private var store

    @State private var showingLogin = false
    @State private var showingSettings = false
    @State private var showingEditProfile = false

    var body: some View {
        Group {
            if auth.isSignedIn {
                signedInContent
            } else {
                signedOutContent
            }
        }
        .navigationTitle("tab.profile")
        .navigationBarTitleDisplayMode(.large)
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
        .sheet(isPresented: $showingLogin) { LoginSheetView() }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(isPresented: $showingEditProfile) { EditProfileView() }
        .navigationDestination(for: Restaurant.self) { restaurant in
            RestaurantDetailView(restaurant: restaurant)
        }
        .task(id: auth.currentUserId) {
            if auth.isSignedIn {
                await store.loadAllMyRatings()
            }
        }
        .onAppear {
            if auth.isSignedIn {
                Task { await store.loadAllMyRatings() }
            }
        }
    }

    // MARK: - Signed-Out

    private var signedOutContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 64))
                    .foregroundStyle(.ffPrimary)
                    .padding(.top, 48)

                VStack(spacing: 8) {
                    Text("profile.signedOutTitle")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .multilineTextAlignment(.center)
                    Text("profile.signedOutSubtitle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Button {
                    showingLogin = true
                } label: {
                    Text("profile.signIn")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.ffPrimary, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
    }

    // MARK: - Signed-In

    private var signedInContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                accountHeader
                statsCard
                ratingsSection
                wantToTrySection
                signOutButton
                    .padding(.top, 12)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .refreshable {
            await store.loadAllMyRatings()
        }
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
                VStack(spacing: 0) {
                    ForEach(Array(ratedEntriesWithRestaurants.enumerated()), id: \.element.0.id) { index, pair in
                        NavigationLink(value: pair.1) {
                            ratingRow(restaurant: pair.1, rating: pair.0.rating)
                        }
                        .buttonStyle(.plain)
                        if index < ratedEntriesWithRestaurants.count - 1 {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
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
                VStack(spacing: 0) {
                    ForEach(Array(wantToTry.enumerated()), id: \.element.id) { index, restaurant in
                        NavigationLink(value: restaurant) {
                            wishlistRow(restaurant: restaurant)
                        }
                        .buttonStyle(.plain)
                        if index < wantToTry.count - 1 {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
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
            AsyncRestaurantImage(url: restaurant.imageUrl.flatMap(URL.init), cuisineIcon: restaurant.cuisineType.icon)
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

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private func wishlistRow(restaurant: Restaurant) -> some View {
        HStack(spacing: 12) {
            AsyncRestaurantImage(url: restaurant.imageUrl.flatMap(URL.init), cuisineIcon: restaurant.cuisineType.icon)
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

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
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
