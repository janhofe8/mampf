import SwiftUI

struct RestaurantRowView: View {
    let restaurant: Restaurant

    var body: some View {
        HStack(spacing: 12) {
            restaurantThumbnail

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(restaurant.name)
                        .font(.headline)
                        .lineLimit(1)

                    if restaurant.isClosed {
                        Text("Closed")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red, in: Capsule())
                    }
                }

                HStack(spacing: 8) {
                    CuisineTag(cuisineType: restaurant.cuisineType)

                    Text(restaurant.neighborhood.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(restaurant.priceRange.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let personal = restaurant.personalRating {
                RatingBadge(value: personal)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var restaurantThumbnail: some View {
        if let urlString = restaurant.imageUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    thumbnailPlaceholder
                default:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.quaternary)
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            thumbnailPlaceholder
        }
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.quaternary)
            .frame(width: 50, height: 50)
            .overlay {
                Text(restaurant.cuisineType.icon)
                    .font(.title3)
            }
    }
}

#Preview {
    List {
        RestaurantRowView(restaurant: Restaurant(
            id: UUID(),
            name: "Lokmam",
            cuisineType: .turkish,
            neighborhood: .ottensen,
            priceRange: .budget,
            address: "Test",
            latitude: 53.55,
            longitude: 9.93,
            openingHours: "Mon-Sun 10:00-22:00",
            isClosed: false,
            notes: "",
            imageUrl: nil,
            personalRating: 9.5,
            googleRating: 4.6,
            googleReviewCount: 820,
            googlePlaceId: nil,
            googleMapsUrl: nil
        ))
    }
}
