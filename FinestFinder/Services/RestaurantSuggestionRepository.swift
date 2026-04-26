import Foundation
import Supabase

actor RestaurantSuggestionRepository {

    private var client: SupabaseClient { SupabaseManager.shared.client }

    /// Submit a new spot suggestion. The DB CHECK constraint requires either a
    /// non-empty google_url or non-empty name — caller must validate before sending.
    func submit(googleUrl: String?, name: String?, locationHint: String?, reason: String?, rating: Double?, userId: UUID?) async throws {
        var row: [String: String?] = [
            "device_id": DeviceID.current,
            "google_url": Self.cleaned(googleUrl),
            "name": Self.cleaned(name),
            "location_hint": Self.cleaned(locationHint),
            "reason": Self.cleaned(reason),
            "rating": rating.map { String($0) },
            "user_id": userId?.uuidString
        ]
        row = row.filter { $0.value != nil }

        try await client
            .from("restaurant_suggestions")
            .insert(row)
            .execute()
    }

    private static func cleaned(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}
