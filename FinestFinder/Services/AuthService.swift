import Foundation
import Supabase
import Observation

@MainActor
@Observable
final class AuthService {
    enum AuthError: LocalizedError {
        case signInFailed(String)
        case signUpFailed(String)
        case signOutFailed(String)
        case updateFailed(String)

        var errorDescription: String? {
            switch self {
            case .signInFailed(let m), .signUpFailed(let m), .signOutFailed(let m), .updateFailed(let m): m
            }
        }
    }

    private(set) var currentUser: User?
    private(set) var isLoading = false

    private var client: SupabaseClient { SupabaseManager.shared.client }

    var isSignedIn: Bool { currentUser != nil }
    var currentUserId: UUID? { currentUser?.id }
    var currentUserEmail: String? { currentUser?.email }
    var currentUserDisplayName: String? {
        guard let user = currentUser else { return nil }
        return user.userMetadata["display_name"]?.stringValue
    }

    init() {
        // Lives for the full app lifetime — no explicit cleanup needed
        Task { [weak self] in
            guard let self else { return }
            for await (_, session) in client.auth.authStateChanges {
                self.currentUser = session?.user
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        do {
            try await client.auth.signIn(email: email, password: password)
        } catch {
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }

    func signUp(email: String, password: String, displayName: String? = nil) async throws {
        isLoading = true
        defer { isLoading = false }
        do {
            var data: [String: AnyJSON] = [:]
            if let displayName, !displayName.trimmingCharacters(in: .whitespaces).isEmpty {
                data["display_name"] = .string(displayName.trimmingCharacters(in: .whitespaces))
            }
            try await client.auth.signUp(
                email: email,
                password: password,
                data: data.isEmpty ? nil : data
            )
        } catch {
            throw AuthError.signUpFailed(error.localizedDescription)
        }
    }

    func signOut() async throws {
        do {
            try await client.auth.signOut()
        } catch {
            throw AuthError.signOutFailed(error.localizedDescription)
        }
    }

    /// Update profile fields. Pass only the values that should change.
    /// - Returns: true if email was changed (caller should inform the user to confirm via email link).
    @discardableResult
    func updateProfile(displayName: String?, email: String?) async throws -> Bool {
        var attrs = UserAttributes()
        var emailChanged = false

        if let email {
            let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if normalized != currentUserEmail?.lowercased() {
                attrs.email = normalized
                emailChanged = true
            }
        }

        if let displayName {
            let trimmed = displayName.trimmingCharacters(in: .whitespaces)
            if trimmed != currentUserDisplayName {
                attrs.data = ["display_name": .string(trimmed)]
            }
        }

        do {
            try await client.auth.update(user: attrs)
        } catch {
            throw AuthError.updateFailed(error.localizedDescription)
        }
        return emailChanged
    }

    struct EmailCheckResult: Decodable {
        let exists: Bool
        let displayName: String?

        enum CodingKeys: String, CodingKey {
            case exists
            case displayName = "display_name"
        }
    }

    /// Permanently deletes the current user's account server-side (calls the `delete_own_account` RPC).
    /// After success, call `signOut()` to clear the local session.
    func deleteAccount() async throws {
        do {
            try await client.rpc("delete_own_account").execute()
        } catch {
            throw AuthError.updateFailed(error.localizedDescription)
        }
    }

    /// Calls the server-side RPC `check_email_exists`. Returns existence + display name (for personalization).
    /// Trade-off: exposes email-existence AND display name for enumeration; acceptable for this use case.
    func checkEmail(_ email: String) async throws -> EmailCheckResult {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let params: [String: String] = ["p_email": normalized]
        let result: EmailCheckResult = try await client
            .rpc("check_email_exists", params: params)
            .execute()
            .value
        return result
    }
}
