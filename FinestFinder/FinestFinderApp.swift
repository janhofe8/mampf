import SwiftUI

@main
struct MAMPFApp: App {
    @State private var store = RestaurantStore()
    @State private var filterVM = FilterViewModel()
    @State private var locationManager = LocationManager()
    @State private var authService = AuthService()

    init() {
        applyBrandedNavBarAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(filterVM)
                .environment(locationManager)
                .environment(authService)
                .task {
                    await store.load()
                }
        }
    }
}
