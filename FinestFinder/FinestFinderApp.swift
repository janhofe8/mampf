import SwiftUI

@main
struct FinestFinderApp: App {
    @State private var store = RestaurantStore()
    @State private var filterVM = FilterViewModel()
    @State private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(filterVM)
                .environment(locationManager)
                .task {
                    await store.load()
                }
        }
    }
}
