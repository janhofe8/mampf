import SwiftUI

struct SettingsView: View {
    @Environment(RestaurantStore.self) private var store
    @Environment(AuthService.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @State private var showDeleteConfirm = false
    @State private var showDeletedBanner = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("settings.appearance", selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .sensoryFeedback(.selection, trigger: appearanceMode)
                } header: {
                    Text("settings.appearanceHeader")
                }

                Section {
                    Text("settings.dataCollectionInfo")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Link(destination: URL(string: "https://mampf-nine.vercel.app/privacy")!) {
                        HStack {
                            Text("settings.privacyPolicy")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("settings.dataCollection")
                }

                Section {
                    Text(auth.isSignedIn ? "settings.deleteAccountInfo" : "settings.deleteDataInfo")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Text(auth.isSignedIn ? "settings.deleteAccount" : "settings.deleteData")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                } header: {
                    Text("settings.privacy")
                }
            }
            .navigationTitle("settings.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("nav.done") { dismiss() }
                        .foregroundStyle(.ffPrimary)
                }
            }
            .confirmationDialog(
                auth.isSignedIn ? "settings.deleteAccountConfirmTitle" : "settings.deleteConfirmTitle",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button(
                    auth.isSignedIn ? "settings.deleteAccountConfirmButton" : "settings.deleteConfirmButton",
                    role: .destructive
                ) {
                    Task {
                        await store.deleteAllData()
                        if auth.isSignedIn {
                            try? await auth.deleteAccount()
                            try? await auth.signOut()
                        }
                        showDeletedBanner = true
                        try? await Task.sleep(for: .seconds(1.5))
                        dismiss()
                    }
                }
                Button("settings.cancel", role: .cancel) {}
            } message: {
                Text(auth.isSignedIn ? "settings.deleteAccountConfirmMessage" : "settings.deleteConfirmMessage")
            }
            .overlay(alignment: .bottom) {
                if showDeletedBanner {
                    Text("settings.dataDeleted")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ffPrimary, in: Capsule())
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 20)
                }
            }
            .animation(.easeInOut, value: showDeletedBanner)
        }
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .system: "settings.appearance.system"
        case .light: "settings.appearance.light"
        case .dark: "settings.appearance.dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

#Preview {
    SettingsView()
        .environment(RestaurantStore())
}
