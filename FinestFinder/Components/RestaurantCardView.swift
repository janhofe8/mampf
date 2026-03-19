import SwiftUI

struct RestaurantCardView: View {
    let restaurant: Restaurant
    let isFavorite: Bool
    let onFavoriteTap: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            cardImage

            // Rating badges top-left
            VStack(alignment: .leading, spacing: 6) {
                if let personal = restaurant.personalRating {
                    ratingPill(icon: "star.fill", value: String(format: personal.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", personal), color: .ffSecondary)
                }
                if let google = restaurant.googleRating {
                    ratingPill(icon: "globe", value: String(format: "%.1f", google), color: .white.opacity(0.9))
                }
            }
            .padding(12)

            // Favorite button top-right
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

            // Bottom gradient with name + info
            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    Text(restaurant.name)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Label(restaurant.neighborhood.displayName, systemImage: "mappin")
                        Text("·")
                        Text("\(restaurant.cuisineType.icon) \(restaurant.cuisineType.displayName)")
                        Spacer()
                        Text(restaurant.priceRange.label)
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))

                    if restaurant.isClosed {
                        Text("Permanently Closed")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.red.opacity(0.9), in: Capsule())
                    }
                }
                .padding(16)
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
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
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
                        .frame(height: 280)
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
            .frame(height: 280)
            .overlay {
                Text(restaurant.cuisineType.icon)
                    .font(.system(size: 60))
                    .opacity(0.5)
            }
    }

    private func ratingPill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
            Text(value)
                .font(.caption.monospacedDigit().bold())
        }
        .foregroundStyle(color == .ffSecondary ? .black : .ffTertiary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
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
            googleReviewCount: 620
        ),
        isFavorite: false,
        onFavoriteTap: {}
    )
    .padding()
}
