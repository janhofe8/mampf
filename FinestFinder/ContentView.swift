import SwiftUI

struct ContentView: View {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

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
                }
            }
        }
        .tint(.ffPrimary)
        .preferredColorScheme(appearanceMode.colorScheme)
    }
}

#Preview {
    ContentView()
        .environment(RestaurantStore())
        .environment(FilterViewModel())
        .environment(LocationManager())
}
