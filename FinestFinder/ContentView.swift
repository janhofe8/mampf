import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("tab.map", systemImage: "map") {
                NavigationStack {
                    MapTabView()
                }
            }

            Tab("tab.restaurants", systemImage: "fork.knife") {
                NavigationStack {
                    RestaurantListView()
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
