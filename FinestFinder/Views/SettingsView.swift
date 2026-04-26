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
                    Link(destination: URL(string: "https://mampf-nine.vercel.app/privacy")!) {
                        settingsRow(
                            icon: "hand.raised",
                            label: "settings.privacyPolicy",
                            trailing: "arrow.up.right.square"
                        )
                    }
                } header: {
                    Text("settings.privacy")
                } footer: {
                    Text("settings.dataCollectionInfo")
                }

                Section {
                    if auth.isSignedIn {
                        Button {
                            Task { try? await auth.signOut() }
                        } label: {
                            settingsRow(icon: "rectangle.portrait.and.arrow.right", label: "profile.signOut")
                        }
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        settingsRow(
                            icon: "trash",
                            label: auth.isSignedIn ? "settings.deleteAccount" : "settings.deleteData",
                            destructive: true
                        )
                    }
                } header: {
                    Text("settings.account")
                } footer: {
                    Text(auth.isSignedIn ? "settings.deleteAccountInfo" : "settings.deleteDataInfo")
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

    @ViewBuilder
    private func settingsRow(icon: String, label: LocalizedStringKey, trailing: String? = nil, destructive: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 24)
                .foregroundStyle(destructive ? .red : .ffPrimary)
            Text(label)
                .foregroundStyle(destructive ? .red : .primary)
            Spacer()
            if let trailing {
                Image(systemName: trailing)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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
