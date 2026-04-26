import SwiftUI

@main
struct MAMPFApp: App {
    @State private var store = RestaurantStore()
    @State private var filterVM = FilterViewModel()
    @State private var locationManager = LocationManager()
    @State private var authService = AuthService()
    @State private var tabRouter = TabRouter()

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
                .environment(tabRouter)
                .task {
                    await store.load()
                }
        }
    }
}
