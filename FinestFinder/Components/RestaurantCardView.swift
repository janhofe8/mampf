import SwiftUI

struct RestaurantCardView: View {
    let restaurant: Restaurant
    let isFavorite: Bool
    let onFavoriteTap: () -> Void
    var compact: Bool = false
    var communityRating: (average: Double, count: Int)? = nil
    var distanceText: String? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            cardImage

            // Ratings top-left
            if compact {
                if let personal = restaurant.personalRating {
                    RatingPill(icon: "star.fill", value: personal.formattedRating, color: RatingSource.personal.color, textColor: .white, size: .compact)
                        .padding(6)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    if let personal = restaurant.personalRating {
                        RatingPill(icon: "star.fill", value: personal.formattedRating, color: RatingSource.personal.color, textColor: .white, size: .large)
                    }
                    if let cr = communityRating {
                        RatingPill(icon: "person.2.fill", value: String(format: "%.1f", cr.average), color: RatingSource.community.color, textColor: .black, size: .small)
                    }
                    if let google = restaurant.googleRating {
                        RatingPill(icon: "globe", value: String(format: "%.1f", google), color: RatingSource.google.color, textColor: .white, size: .small)
                    }
                }
                .padding(12)
            }

            // Favorite button top-right (hidden in compact)
            if !compact {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onFavoriteTap) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(isFavorite ? .red : .white)
                                .frame(width: 36, height: 36)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .sensoryFeedback(.impact(weight: .medium), trigger: isFavorite)
                        .padding(12)
                    }
                    Spacer()
                }
            }

            // Bottom gradient with name + info
            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: compact ? 2 : 6) {
                    Text(restaurant.name)
                        .font(compact ? .caption.bold() : .title2.bold())
                        .foregroundStyle(.white)
                        .lineLimit(compact ? 1 : 2)

                    if compact {
                        HStack(spacing: 3) {
                            Text(restaurant.cuisineType.icon)
                                .font(.system(size: 10))
                            Text(restaurant.neighborhood.displayName)
                            Text("·")
                            Text(restaurant.priceRange.label)
                        }
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                    } else {
                        HStack(spacing: 8) {
                            if let isOpen = restaurant.isOpenNow {
                                Circle()
                                    .fill(isOpen ? .green : .red)
                                    .frame(width: 6, height: 6)
                            }
                            Label(restaurant.neighborhood.displayName, systemImage: "mappin")
                            Text("·")
                            HStack(spacing: 2) {
                                Text(restaurant.cuisineType.icon).font(.system(size: 12))
                                Text(restaurant.cuisineType.displayName)
                            }
                            Spacer()
                            if let dist = distanceText {
                                Label(dist, systemImage: "location")
                                Text("·")
                            }
                            Text(restaurant.priceRange.label)
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                    }

                    if restaurant.isClosed {
                        Text("card.closed")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, compact ? 6 : 8)
                            .padding(.vertical, 3)
                            .background(.red.opacity(0.9), in: Capsule())
                    }
                }
                .padding(compact ? 8 : 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .frame(height: compact ? 120 : 280)
        .clipShape(RoundedRectangle(cornerRadius: compact ? 12 : 20))
        .shadow(color: .black.opacity(0.15), radius: compact ? 5 : 10, y: compact ? 2 : 5)
    }

    private var cardImage: some View {
        AsyncRestaurantImage(
            url: restaurant.imageUrl.flatMap(URL.init),
            cuisineIcon: restaurant.cuisineType.icon,
            cornerRadius: compact ? 12 : 20,
            showProgress: true,
            gradient: true
        )
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
    }

}

#Preview {
    RestaurantCardView(
        restaurant: Restaurant(
            id: UUID(),
            name: "Pizzamacher Trattoria",
            cuisineType: .pizza,
            neighborhood: .ottensen,
            priceRange: .moderate,
            address: "Friedensallee 26",
            latitude: 53.55,
            longitude: 9.93,
            openingHours: "Tue-Sun 12:00-22:30",
            isClosed: false,
            notes: "",
            imageUrl: nil,
            personalRating: 9.5,
            googleRating: 4.7,
            googleReviewCount: 620,
            googlePlaceId: nil,
            googleMapsUrl: nil,
            createdAt: nil
        ),
        isFavorite: false,
        onFavoriteTap: {}
    )
    .padding()
}
