import SwiftUI
import MapKit

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    @Environment(RestaurantStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                restaurantImage
                header
                RatingComparisonCard(ratings: restaurant.ratings)
                infoCard
                miniMap
            }
            .padding()
        }
        .navigationTitle(restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.toggleFavorite(restaurant)
                } label: {
                    Image(systemName: store.isFavorite(restaurant) ? "heart.fill" : "heart")
                        .foregroundStyle(store.isFavorite(restaurant) ? .red : .secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var restaurantImage: some View {
        if let urlString = restaurant.imageUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                case .failure:
                    imagePlaceholder
                default:
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.quaternary)
                        .frame(height: 220)
                        .overlay { ProgressView() }
                }
            }
        } else {
            imagePlaceholder
        }
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.quaternary)
            .frame(height: 220)
            .overlay {
                Text(restaurant.cuisineType.icon)
                    .font(.system(size: 60))
            }
    }

    private var header: some View {
        HStack(spacing: 10) {
            CuisineTag(cuisineType: restaurant.cuisineType)

            if restaurant.isClosed {
                Text("Permanently Closed")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.red, in: Capsule())
            }

            Spacer()

            Text(restaurant.priceRange.label)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
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
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
        }
    }

    private var miniMap: some View {
        Map {
            Marker(restaurant.name, coordinate: restaurant.coordinate)
                .tint(restaurant.personalRating.map { ratingColor(for: $0 / 10) } ?? .blue)
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
