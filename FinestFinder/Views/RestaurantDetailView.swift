import SwiftUI
import MapKit

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    @Environment(RestaurantStore.self) private var store
    @State private var userRating: Double = 0
    @State private var hasSubmitted = false

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
                Button {
                    store.toggleFavorite(restaurant)
                } label: {
                    Image(systemName: store.isFavorite(restaurant) ? "heart.fill" : "heart")
                        .foregroundStyle(store.isFavorite(restaurant) ? .red : .white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
        }
    }

    @ViewBuilder
    private var heroImage: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                if let urlString = restaurant.imageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: 350)
                                .clipped()
                        case .failure:
                            heroPlaceholder
                        default:
                            heroPlaceholder
                                .overlay { ProgressView().tint(.white) }
                        }
                    }
                } else {
                    heroPlaceholder
                }

                // Gradient overlay with name
                VStack(alignment: .leading, spacing: 8) {
                    if restaurant.isClosed {
                        Text("Permanently Closed")
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

    private var heroPlaceholder: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.ffPrimary, .ffTertiary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 350)
            .overlay {
                Text(restaurant.cuisineType.icon)
                    .font(.system(size: 80))
                    .opacity(0.4)
            }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            RatingComparisonCard(ratings: store.ratingsIncludingCommunity(for: restaurant))
            userRatingCard
            infoCard
            miniMap
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
            Text("Deine Bewertung")
                .font(.headline)

            HStack {
                Text(userRating > 0 ? String(format: userRating.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", userRating) : "–")
                    .font(.system(size: 28, weight: .black).monospacedDigit())
                    .foregroundStyle(userRating > 0 ? .primary : .secondary)
                    .lineLimit(1)
                    .fixedSize()
                    .frame(minWidth: 40)

                Slider(value: $userRating, in: 1...10, step: 0.5)
                    .tint(RatingSource.community.color)

                Text("/ 10")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button {
                    Task {
                        await store.submitRating(for: restaurant, rating: userRating)
                        hasSubmitted = true
                    }
                } label: {
                    Text(hasSubmitted ? "Aktualisieren" : "Bewerten")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(userRating > 0 ? Color.ffPrimary : Color.gray.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.white)
                }
                .disabled(userRating == 0)

                if hasSubmitted {
                    Button {
                        Task {
                            await store.deleteRating(for: restaurant)
                            userRating = 0
                            hasSubmitted = false
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.subheadline.weight(.semibold))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(Color.gray.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Info")
                .font(.headline)

            infoRow(icon: "mappin.circle.fill", label: restaurant.address)
            openingHoursView
            infoRow(icon: "map.fill", label: restaurant.neighborhood.displayName)

            if let urlString = restaurant.googleMapsUrl, let url = URL(string: urlString) {
                Link(destination: url) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.up.right.square.fill")
                            .foregroundStyle(.ffPrimary)
                            .frame(width: 24)
                        Text("In Google Maps öffnen")
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

    private var openingHoursView: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "clock.fill")
                .foregroundStyle(.ffPrimary)
                .frame(width: 24)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
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

    private func infoRow(icon: String, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.ffPrimary)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
        }
    }

    private var miniMap: some View {
        Map {
            Marker(restaurant.name, coordinate: restaurant.coordinate)
                .tint(.ffPrimary)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .allowsHitTesting(false)
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
