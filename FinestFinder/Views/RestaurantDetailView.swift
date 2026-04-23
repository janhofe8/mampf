import SwiftUI
import MapKit

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    @Environment(RestaurantStore.self) private var store
    @State private var userRating: Double = 0
    @State private var hasSubmitted = false
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    private let notificationFeedback = UINotificationFeedbackGenerator()

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroImage
                content
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 8) {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Button {
                        store.toggleFavorite(restaurant)
                    } label: {
                        Image(systemName: store.isFavorite(restaurant) ? "heart.fill" : "heart")
                            .foregroundStyle(store.isFavorite(restaurant) ? .red : .white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .sensoryFeedback(.impact(weight: .medium), trigger: store.isFavorite(restaurant))
                    .accessibilityLabel(store.isFavorite(restaurant)
                        ? String(localized: "a11y.removeFavorite")
                        : String(localized: "a11y.addFavorite"))
                }
            }
        }
    }

    @ViewBuilder
    private var heroImage: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                AsyncRestaurantImage(
                    url: restaurant.imageUrl.flatMap(URL.init),
                    cuisineIcon: restaurant.cuisineType.icon,
                    cornerRadius: 0,
                    showProgress: true,
                    gradient: true
                )
                .frame(width: geo.size.width, height: 350)
                .clipped()

                // Gradient overlay with name
                VStack(alignment: .leading, spacing: 8) {
                    if restaurant.isClosed {
                        Text("detail.closed")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.red.opacity(0.9), in: Capsule())
                    }

                    Text(restaurant.name)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    HStack(spacing: 10) {
                        HStack(spacing: 4) {
                            Text(restaurant.cuisineType.icon)
                                .font(.system(size: 14))
                            Text(restaurant.cuisineType.displayName)
                                .font(.caption)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.2), in: Capsule())
                        Text(restaurant.priceRange.label)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .frame(height: 350)
    }


    private var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            RatingComparisonCard(ratings: store.ratingsIncludingCommunity(for: restaurant))
            userRatingCard
            infoCard
            if !restaurant.notes.isEmpty {
                notesCard
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .task {
            await store.loadMyRating(for: restaurant)
            if let existing = store.myRating(for: restaurant) {
                userRating = existing
                hasSubmitted = true
            }
        }
    }

    private var userRatingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("detail.yourRating")
                .font(.headline)

            if !hasSubmitted && store.communityRating(for: restaurant) == nil {
                Label("detail.beFirstToRate", systemImage: "sparkles")
                    .font(.subheadline)
                    .foregroundStyle(.ffPrimary)
            }

            HStack {
                Text(userRating > 0 ? userRating.formattedRating : "–")
                    .font(.system(size: 28, weight: .black).monospacedDigit())
                    .foregroundStyle(userRating > 0 ? .primary : .secondary)
                    .lineLimit(1)
                    .fixedSize()
                    .frame(minWidth: 40)

                Slider(value: $userRating, in: 1...10, step: 0.5)
                    .tint(RatingSource.community.color)
                    .sensoryFeedback(.selection, trigger: userRating)
                    .accessibilityLabel(String(localized: "a11y.rating"))
                    .accessibilityValue(String(format: String(localized: "a11y.ratingValue"), userRating.formattedRating))

                Text("detail.outOf10")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button {
                    guard validatedRating != nil else { return }
                    Task {
                        isSubmitting = true
                        await store.submitRating(for: restaurant, rating: userRating)
                        if store.error != nil {
                            errorMessage = String(localized: "error.ratingFailed")
                            showError = true
                            notificationFeedback.notificationOccurred(.error)
                        } else {
                            hasSubmitted = true
                            notificationFeedback.notificationOccurred(.success)
                        }
                        isSubmitting = false
                    }
                } label: {
                    Group {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(hasSubmitted ? String(localized: "detail.update") : String(localized: "detail.rate"))
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(validatedRating != nil ? Color.ffPrimary : Color.gray.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
                }
                .disabled(validatedRating == nil || isSubmitting)

                if hasSubmitted {
                    Button {
                        Task {
                            isSubmitting = true
                            await store.deleteRating(for: restaurant)
                            if store.error != nil {
                                errorMessage = String(localized: "error.deleteFailed")
                                showError = true
                                notificationFeedback.notificationOccurred(.error)
                            } else {
                                userRating = 0
                                hasSubmitted = false
                                notificationFeedback.notificationOccurred(.warning)
                            }
                            isSubmitting = false
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.subheadline.weight(.semibold))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(Color.gray.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.red)
                    }
                    .disabled(isSubmitting)
                }
            }
            .alert(String(localized: "error.title"), isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("detail.info")
                .font(.headline)

            // Mini-Map
            Map(initialPosition: .region(MKCoordinateRegion(
                center: restaurant.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))) {
                Marker(restaurant.name, coordinate: restaurant.coordinate)
                    .tint(.ffPrimary)
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .allowsHitTesting(false)

            infoRow(icon: "mappin.circle.fill", label: restaurant.address)
            openingHoursView
            infoRow(icon: "map.fill", label: restaurant.neighborhood.displayName)

            if let urlString = restaurant.googleMapsUrl, let url = URL(string: urlString) {
                Link(destination: url) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.up.right.square.fill")
                            .foregroundStyle(.ffPrimary)
                            .frame(width: 24)
                        Text("detail.openInGoogleMaps")
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("detail.notes")
                .font(.headline)
            Text(restaurant.notes)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var openingHoursView: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "clock.fill")
                .foregroundStyle(.ffPrimary)
                .frame(width: 24)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                if let isOpen = restaurant.isOpenNow {
                    Text(isOpen ? "status.open" : "status.closed")
                        .font(.subheadline.bold())
                        .foregroundStyle(isOpen ? .green : .red)
                }
                let days = restaurant.openingHours
                    .components(separatedBy: "; ")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                ForEach(days, id: \.self) { day in
                    Text(day)
                        .font(.subheadline)
                }
            }
        }
    }

    /// Returns the rating if valid (1-10, 0.5 steps), nil otherwise.
    private var validatedRating: Double? {
        guard userRating >= 1, userRating <= 10 else { return nil }
        let rounded = (userRating * 2).rounded() / 2
        guard rounded == userRating else { return nil }
        return userRating
    }

    private var shareText: String {
        var text = restaurant.name
        if let rating = restaurant.personalRating {
            text += " — MAMPF Rating: \(rating.formattedRating)/10"
        }
        text += "\n\(restaurant.cuisineType.icon) \(restaurant.cuisineType.displayName) · \(restaurant.neighborhood.displayName) · \(restaurant.priceRange.label)"
        if let url = restaurant.googleMapsUrl {
            text += "\n\(url)"
        }
        return text
    }

    private func infoRow(icon: String, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.ffPrimary)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
        }
    }

}

#Preview {
    NavigationStack {
        RestaurantDetailView(restaurant: Restaurant(
            id: UUID(),
            name: "Lokmam",
            cuisineType: .turkish,
            neighborhood: .ottensen,
            priceRange: .budget,
            address: "Ottenser Hauptstraße 52, 22765 Hamburg",
            latitude: 53.5520,
            longitude: 9.9290,
            openingHours: "Mon-Sun 10:00-22:00",
            isClosed: false,
            notes: "",
            imageUrl: nil,
            personalRating: 9.5,
            googleRating: 4.6,
            googleReviewCount: 820,
            googlePlaceId: nil,
            googleMapsUrl: "https://maps.google.com/?cid=12345",
            createdAt: nil
        ))
    }
    .environment(RestaurantStore())
}
