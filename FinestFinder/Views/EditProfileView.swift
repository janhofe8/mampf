import SwiftUI

struct EditProfileView: View {
    @Environment(AuthService.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var submitting = false
    @State private var errorMessage: String?
    @State private var showEmailConfirmationHint = false
    @FocusState private var focus: Field?

    private enum Field { case name, email }

    private var hasChanges: Bool {
        let nameChanged = displayName.trimmingCharacters(in: .whitespaces) != (auth.currentUserDisplayName ?? "")
        let emailChanged = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            != (auth.currentUserEmail ?? "").lowercased()
        return nameChanged || emailChanged
    }

    private var emailLooksValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".") && trimmed.count >= 5
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("login.namePlaceholder", text: $displayName)
                        .textContentType(.givenName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .name)
                } header: {
                    Text("editProfile.nameSection")
                }

                Section {
                    TextField("login.email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .email)
                } header: {
                    Text("editProfile.emailSection")
                } footer: {
                    Text("editProfile.emailNote")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }

                if showEmailConfirmationHint {
                    Section {
                        Label("editProfile.emailConfirmationSent", systemImage: "envelope.badge")
                            .font(.subheadline)
                            .foregroundStyle(.ffPrimary)
                    }
                }
            }
            .navigationTitle("editProfile.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("nav.cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("editProfile.save") {
                        Task { await save() }
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
            .overlay {
                if submitting {
                    Color.black.opacity(0.1).ignoresSafeArea()
                    ProgressView()
                }
            }
            .onAppear {
                displayName = auth.currentUserDisplayName ?? ""
                email = auth.currentUserEmail ?? ""
            }
        }
    }

    private var canSave: Bool {
        !submitting && hasChanges && emailLooksValid
    }

    private func save() async {
        guard canSave else { return }
        submitting = true
        errorMessage = nil
        defer { submitting = false }

        do {
            let emailChanged = try await auth.updateProfile(displayName: displayName, email: email)
            if emailChanged {
                showEmailConfirmationHint = true
                // Don't dismiss — let the user see the confirmation note
            } else {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    EditProfileView()
        .environment(AuthService())
}
