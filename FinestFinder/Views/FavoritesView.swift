import SwiftUI

struct FavoritesView: View {
    @Environment(RestaurantStore.self) private var store

    var body: some View {
        Group {
            if store.favorites.isEmpty {
                ContentUnavailableView(
                    "No Favorites",
                    systemImage: "heart.slash",
                    description: Text("Tap the heart icon on a restaurant to add it to your favorites.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(store.favorites) { restaurant in
                            NavigationLink(value: restaurant) {
                                RestaurantCardView(
                                    restaurant: restaurant,
                                    isFavorite: true,
                                    onFavoriteTap: { store.toggleFavorite(restaurant) },
                                    communityRating: store.communityRating(for: restaurant)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
        }
        .navigationTitle("Favorites")
    }
}

#Preview {
    NavigationStack {
        FavoritesView()
    }
    .environment(RestaurantStore())
}
