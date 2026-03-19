import SwiftUI
import MapKit

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    @Environment(RestaurantStore.self) private var store

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
        ZStack(alignment: .bottomLeading) {
            if let urlString = restaurant.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 350)
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
                    CuisineTag(cuisineType: restaurant.cuisineType)
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
            RatingComparisonCard(ratings: restaurant.ratings)
            infoCard
            miniMap
        }
        .padding(20)
        .background(Color(.systemBackground))
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Info")
                .font(.headline)

            infoRow(icon: "mappin.circle.fill", label: restaurant.address)
            infoRow(icon: "clock.fill", label: restaurant.openingHours)
            infoRow(icon: "map.fill", label: restaurant.neighborhood.displayName)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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
            googleReviewCount: 820
        ))
    }
    .environment(RestaurantStore())
}
