import SwiftUI

struct RestaurantCardView: View {
    let restaurant: Restaurant
    let isFavorite: Bool
    let onFavoriteTap: () -> Void
    var compact: Bool = false
    var communityRating: (average: Double, count: Int)? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            cardImage

            // Ratings top-left
            if compact {
                if let personal = restaurant.personalRating {
                    compactPill(icon: "star.fill", value: String(format: personal.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", personal), color: RatingSource.personal.color, textColor: .white)
                        .padding(6)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    if let personal = restaurant.personalRating {
                        HStack(spacing: 5) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text(String(format: personal.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", personal))
                                .font(.system(size: 26, weight: .black).monospacedDigit())
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(RatingSource.personal.color, in: Capsule())
                    }
                    if let cr = communityRating {
                        smallPill(icon: "person.2.fill", value: String(format: "%.1f", cr.average), color: RatingSource.community.color, textColor: .black)
                    }
                    if let google = restaurant.googleRating {
                        smallPill(icon: "globe", value: String(format: "%.1f", google), color: RatingSource.google.color, textColor: .white)
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

                    if !compact {
                        HStack(spacing: 8) {
                            Label(restaurant.neighborhood.displayName, systemImage: "mappin")
                            Text("·")
                            HStack(spacing: 2) {
                                Text(restaurant.cuisineType.icon).font(.system(size: 12))
                                Text(restaurant.cuisineType.displayName)
                            }
                            Spacer()
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

    @ViewBuilder
    private var cardImage: some View {
        if let urlString = restaurant.imageUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                case .failure:
                    placeholderImage
                default:
                    placeholderImage
                        .overlay { ProgressView().tint(.white) }
                }
            }
        } else {
            placeholderImage
        }
    }

    private var placeholderImage: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.ffPrimary.opacity(0.8), .ffTertiary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: compact ? 120 : 280)
            .overlay {
                Text(restaurant.cuisineType.icon)
                    .font(.system(size: compact ? 36 : 60))
                    .opacity(0.5)
            }
    }

    private func compactPill(icon: String, value: String, color: Color, textColor: Color) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
                .frame(width: 10)
            Text(value)
                .font(.system(size: 12, weight: .black).monospacedDigit())
        }
        .foregroundStyle(textColor)
        .frame(minWidth: 44)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color, in: Capsule())
    }

    private func smallPill(icon: String, value: String, color: Color, textColor: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .frame(width: 14)
            Text(value)
                .font(.system(size: 14, weight: .bold).monospacedDigit())
        }
        .foregroundStyle(textColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color, in: Capsule())
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
