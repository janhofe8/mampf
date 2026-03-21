import SwiftUI

struct SettingsView: View {
    @Environment(RestaurantStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    @State private var showDeletedBanner = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("settings.dataCollectionInfo")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("settings.dataCollection")
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("settings.deleteData", systemImage: "trash")
                    }

                    Text("settings.deleteDataInfo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
            .confirmationDialog("settings.deleteConfirmTitle", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("settings.deleteConfirmButton", role: .destructive) {
                    Task {
                        await store.deleteAllData()
                        showDeletedBanner = true
                        try? await Task.sleep(for: .seconds(1.5))
                        dismiss()
                    }
                }
                Button("settings.cancel", role: .cancel) {}
            } message: {
                Text("settings.deleteConfirmMessage")
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

#Preview {
    SettingsView()
        .environment(RestaurantStore())
}
