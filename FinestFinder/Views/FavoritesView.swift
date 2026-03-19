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
                List(store.favorites) { restaurant in
                    NavigationLink(value: restaurant) {
                        RestaurantRowView(restaurant: restaurant)
                    }
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
