import SwiftUI

struct ContentView: View {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(RestaurantStore.self) private var store
    @Environment(AuthService.self) private var auth
    @State private var visibleError: String?

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

            Tab("tab.profile", systemImage: "person.crop.circle") {
                NavigationStack {
                    ProfileTabView()
                }
            }
        }
        .tint(.ffPrimary)
        .preferredColorScheme(appearanceMode.colorScheme)
        .task(id: auth.currentUserId) {
            await store.setCurrentUser(auth.currentUserId)
        }
        .overlay(alignment: .top) {
            if let message = visibleError {
                ErrorToast(message: message)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 50)
                    .zIndex(100)
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { !hasCompletedOnboarding },
            set: { if !$0 { hasCompletedOnboarding = true } }
        )) {
            OnboardingView()
        }
        .onChange(of: store.error?.localizedDescription) { _, newValue in
            guard let desc = newValue else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                visibleError = desc
            }
            Task {
                try? await Task.sleep(for: .seconds(4))
                withAnimation(.easeInOut(duration: 0.25)) {
                    visibleError = nil
                }
            }
        }
    }
}

private struct ErrorToast: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.red.gradient, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .padding(.horizontal, 20)
    }
}

#Preview {
    ContentView()
        .environment(RestaurantStore())
        .environment(FilterViewModel())
        .environment(LocationManager())
}
