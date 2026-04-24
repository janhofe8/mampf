import SwiftUI

struct LoginSheetView: View {
    enum Mode { case signIn, signUp }
    enum Step { case email, password, name }

    @Environment(AuthService.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var mode: Mode = .signIn
    @State private var step: Step = .email
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var displayName: String = ""
    /// Pre-fetched display name for returning users (shown as "Welcome back, Jan!").
    @State private var returningUserName: String?
    @State private var errorMessage: String?
    @State private var submitting = false
    @State private var checkingEmail = false
    @FocusState private var focus: Field?

    private enum Field { case email, password, name }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .email: emailStep
                case .password: passwordStep
                case .name: nameStep
                }
            }
            .animation(.easeInOut(duration: 0.2), value: step)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if step == .email {
                        Button("nav.cancel") { dismiss() }
                    } else {
                        Button {
                            withAnimation { goBack() }
                        } label: {
                            Label("nav.back", systemImage: "chevron.left")
                                .labelStyle(.iconOnly)
                        }
                    }
                }
            }
        }
    }

    private var navigationTitle: LocalizedStringKey {
        switch (step, mode) {
        case (.email, _): "login.title"
        case (.password, .signIn): "login.title"
        case (.password, .signUp): "login.titleSignup"
        case (.name, _): "login.titleSignup"
        }
    }

    // MARK: - Step 1: Email

    private var emailStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("login.emailHeader")
                    .font(.title2.weight(.bold))
                Text("login.emailSubtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)
            .padding(.horizontal, 20)

            TextField("login.email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focus, equals: .email)
                .submitLabel(.next)
                .onSubmit { Task { await advanceToPassword() } }
                .padding(14)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
                .padding(.top, 24)

            if let errorMessage, step == .email {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
            }

            Spacer(minLength: 0)

            Button {
                Task { await advanceToPassword() }
            } label: {
                HStack {
                    Spacer()
                    if checkingEmail {
                        ProgressView().tint(.white)
                    } else {
                        Text("login.continue")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(Color.ffPrimary.opacity(emailLooksValid && !checkingEmail ? 1.0 : 0.4), in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!emailLooksValid || checkingEmail)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .onAppear { focus = .email }
        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
    }

    // MARK: - Step 2: Password

    private var passwordStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(passwordStepHeader)
                    .font(.title2.weight(.bold))
                Text(email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.top, 24)
            .padding(.horizontal, 20)

            // Hidden but present — lets iCloud Keychain pair email with the password
            TextField("", text: .constant(email))
                .textContentType(.username)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .disabled(true)
                .frame(width: 0, height: 0)
                .opacity(0)
                .accessibilityHidden(true)

            SecureField("login.password", text: $password)
                .textContentType(mode == .signUp ? .newPassword : .password)
                .focused($focus, equals: .password)
                .submitLabel(mode == .signUp ? .next : .go)
                .onSubmit { Task { await passwordStepPrimary() } }
                .padding(14)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
                .padding(.top, 24)

            if let errorMessage, step == .password {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
            }

            Button {
                withAnimation { mode = (mode == .signIn ? .signUp : .signIn) }
                errorMessage = nil
            } label: {
                Text(mode == .signIn ? "login.toggle.toSignup" : "login.toggle.toSignin")
                    .font(.footnote)
                    .foregroundStyle(.ffPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Spacer(minLength: 0)

            Button {
                Task { await passwordStepPrimary() }
            } label: {
                HStack {
                    Spacer()
                    if submitting {
                        ProgressView().tint(.white)
                    } else {
                        Text(mode == .signIn ? "login.submit.signIn" : "login.continue")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(Color.ffPrimary.opacity(canSubmitPassword ? 1.0 : 0.4), in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canSubmitPassword)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .onAppear { focus = .password }
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
    }

    // MARK: - Step 3: Name (Signup only)

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("login.nameHeader")
                    .font(.title2.weight(.bold))
                Text("login.nameSubtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)
            .padding(.horizontal, 20)

            TextField("login.namePlaceholder", text: $displayName)
                .textContentType(.givenName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($focus, equals: .name)
                .submitLabel(.go)
                .onSubmit { Task { await submit() } }
                .padding(14)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
                .padding(.top, 24)

            if let errorMessage, step == .name {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
            }

            Spacer(minLength: 0)

            Button {
                Task { await submit() }
            } label: {
                HStack {
                    Spacer()
                    if submitting {
                        ProgressView().tint(.white)
                    } else {
                        Text("login.submit.signUp")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(Color.ffPrimary.opacity(canSubmitName ? 1.0 : 0.4), in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canSubmitName)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .onAppear { focus = .name }
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
    }

    // MARK: - Validation & Actions

    private var emailLooksValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".") && trimmed.count >= 5
    }

    private var canSubmitPassword: Bool {
        !submitting && password.count >= 6
    }

    private var passwordStepHeader: String {
        switch mode {
        case .signIn:
            if let name = returningUserName {
                return String(format: String(localized: "login.welcomeBackNamed"), name)
            } else {
                return String(localized: "login.passwordHeader")
            }
        case .signUp:
            return String(localized: "login.passwordHeaderSignup")
        }
    }

    private var canSubmitName: Bool {
        !submitting && !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func advanceToPassword() async {
        guard emailLooksValid else {
            errorMessage = String(localized: "login.error.emailInvalid")
            return
        }
        email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        errorMessage = nil
        checkingEmail = true
        defer { checkingEmail = false }

        do {
            let check = try await auth.checkEmail(email)
            mode = check.exists ? .signIn : .signUp
            let trimmed = check.displayName?.trimmingCharacters(in: .whitespaces) ?? ""
            returningUserName = trimmed.isEmpty ? nil : trimmed
        } catch {
            // Detection failed — default to sign-in; user can toggle manually if needed
            mode = .signIn
            returningUserName = nil
        }
        withAnimation { step = .password }
    }

    private func goBack() {
        switch step {
        case .password:
            step = .email
            password = ""
        case .name:
            step = .password
            displayName = ""
        case .email:
            break
        }
        errorMessage = nil
    }

    /// Called from password step — for sign-in, submits directly; for sign-up, advances to the name step.
    private func passwordStepPrimary() async {
        guard canSubmitPassword else { return }
        errorMessage = nil
        switch mode {
        case .signIn:
            await submit()
        case .signUp:
            withAnimation { step = .name }
        }
    }

    private func submit() async {
        submitting = true
        errorMessage = nil
        defer { submitting = false }

        do {
            switch mode {
            case .signIn:
                try await auth.signIn(email: email, password: password)
            case .signUp:
                try await auth.signUp(email: email, password: password, displayName: displayName)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    LoginSheetView()
        .environment(AuthService())
}
