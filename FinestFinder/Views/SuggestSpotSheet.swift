import SwiftUI

struct SuggestSpotSheet: View {
    @Environment(AuthService.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var googleUrl: String = ""
    @State private var name: String = ""
    @State private var locationHint: String = ""
    @State private var reason: String = ""
    @State private var rating: Double = 0   // 0 = unrated (RatingSlider treats <1 as unset)
    @State private var submitting: Bool = false
    @State private var didSucceed: Bool = false
    @State private var errorMessage: String?
    @FocusState private var focus: Field?

    private let repo = RestaurantSuggestionRepository()

    private enum Field { case url, name, hint, reason }

    private var hasUrl: Bool { !googleUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var hasName: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var canSubmit: Bool { !submitting && (hasUrl || hasName) }

    var body: some View {
        NavigationStack {
            Group {
                if didSucceed { successView } else { formView }
            }
            .navigationTitle("suggest.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("nav.cancel") { dismiss() }
                }
                if !didSucceed {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("suggest.submit") {
                            Task { await submit() }
                        }
                        .disabled(!canSubmit)
                        .fontWeight(.semibold)
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("nav.done") { focus = nil }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var formView: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("suggest.intro.title")
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                    Text("suggest.intro.subtitle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
            }

            Section {
                HStack(spacing: 8) {
                    TextField("suggest.urlPlaceholder", text: $googleUrl, axis: .vertical)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .url)
                        .lineLimit(1...3)
                    if googleUrl.isEmpty {
                        PasteButton(payloadType: String.self) { strings in
                            if let pasted = strings.first {
                                Task { @MainActor in googleUrl = pasted }
                            }
                        }
                        .labelStyle(.iconOnly)
                        .buttonBorderShape(.capsule)
                        .tint(.ffPrimary)
                    } else {
                        Button {
                            googleUrl = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                sectionHeader("suggest.urlSection")
            } footer: {
                Text("suggest.urlHint")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                TextField("suggest.namePlaceholder", text: $name)
                    .textInputAutocapitalization(.words)
                    .focused($focus, equals: .name)
                TextField("suggest.locationPlaceholder", text: $locationHint)
                    .textInputAutocapitalization(.words)
                    .focused($focus, equals: .hint)
            } header: {
                sectionHeader("suggest.fallbackSection")
            } footer: {
                Text("suggest.fallbackHint")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                VStack(spacing: 8) {
                    HStack {
                        Text(rating < 1 ? String(localized: "suggest.rating.unrated") : rating.formattedRating + "/10")
                            .font(.system(.title3, design: .rounded).weight(.heavy))
                            .foregroundStyle(rating < 1 ? Color.secondary : Color.ratingColor(for: rating))
                            .contentTransition(.numericText())
                        Spacer()
                        if rating >= 1 {
                            Button {
                                rating = 0
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    RatingSlider(value: $rating)
                }
                .padding(.vertical, 6)
            } header: {
                sectionHeader("suggest.rating.section")
            } footer: {
                Text("suggest.rating.hint")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                TextField("suggest.reasonPlaceholder", text: $reason, axis: .vertical)
                    .focused($focus, equals: .reason)
                    .lineLimit(2...5)
            } header: {
                sectionHeader("suggest.reasonSection")
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .overlay {
            if submitting {
                Color.black.opacity(0.1).ignoresSafeArea()
                ProgressView()
            }
        }
    }

    private func sectionHeader(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(nil)
    }

    private var successView: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.ffPrimary.opacity(0.14))
                    .frame(width: 88, height: 88)
                Image(systemName: "checkmark")
                    .font(.system(size: 38, weight: .heavy))
                    .foregroundStyle(.ffPrimary)
            }
            VStack(spacing: 8) {
                Text("suggest.success.title")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                Text("suggest.success.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("suggest.success.done")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.ffPrimary, in: Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private func submit() async {
        guard canSubmit else { return }
        submitting = true
        errorMessage = nil
        defer { submitting = false }

        do {
            try await repo.submit(
                googleUrl: googleUrl,
                name: name,
                locationHint: locationHint,
                reason: reason,
                rating: rating >= 1 ? rating : nil,
                userId: auth.currentUserId
            )
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation { didSucceed = true }
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    SuggestSpotSheet()
        .environment(AuthService())
}
