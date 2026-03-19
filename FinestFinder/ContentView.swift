import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Restaurants", systemImage: "fork.knife") {
                NavigationStack {
                    RestaurantListView()
                        .navigationDestination(for: Restaurant.self) { restaurant in
                            RestaurantDetailView(restaurant: restaurant)
                        }
                }
            }

            Tab("Map", systemImage: "map") {
                NavigationStack {
                    MapTabView()
                }
            }

            Tab("Favorites", systemImage: "heart.fill") {
                NavigationStack {
                    FavoritesView()
                        .navigationDestination(for: Restaurant.self) { restaurant in
                            RestaurantDetailView(restaurant: restaurant)
                        }
                }
            }
        }
        .tint(.ffPrimary)
    }
}

#Preview {
    ContentView()
        .environment(RestaurantStore())
        .environment(FilterViewModel())
}
