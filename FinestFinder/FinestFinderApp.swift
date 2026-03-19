import SwiftUI

@main
struct FinestFinderApp: App {
    @State private var store = RestaurantStore()
    @State private var filterVM = FilterViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(filterVM)
                .task { await store.load() }
        }
    }
}
