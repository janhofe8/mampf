import Foundation
import Supabase

actor UserRatingRepository {

    struct UserRatingRow: Codable {
        let id: UUID?
        let restaurantId: UUID
        let deviceId: String
        let userId: UUID?
        let rating: Double
        let createdAt: Date?
        let updatedAt: Date?

        enum CodingKeys: String, CodingKey {
            case id
            case restaurantId = "restaurant_id"
            case deviceId = "device_id"
            case userId = "user_id"
            case rating
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }

    struct CommunityRating: Codable {
        let restaurantId: UUID
        let communityRating: Double
        let communityRatingCount: Int

        enum CodingKeys: String, CodingKey {
            case restaurantId = "restaurant_id"
            case communityRating = "community_rating"
            case communityRatingCount = "community_rating_count"
        }
    }

    private var client: SupabaseClient { SupabaseManager.shared.client }

    private let communityCacheURL: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("community_ratings_cache.json")
    }()

    /// Fetch community averages for all restaurants
    func fetchCommunityRatings() async throws -> [UUID: (average: Double, count: Int)] {
        let rows: [CommunityRating] = try await client
            .from("restaurant_community_ratings")
            .select()
            .execute()
            .value

        cacheCommunityRatings(rows)
        return Self.mapCommunityRows(rows)
    }

    /// Offline fallback — community averages from the last successful fetch.
    func loadCachedCommunityRatings() -> [UUID: (average: Double, count: Int)] {
        guard let data = try? Data(contentsOf: communityCacheURL),
              let rows = try? JSONDecoder().decode([CommunityRating].self, from: data)
        else { return [:] }
        return Self.mapCommunityRows(rows)
    }

    private func cacheCommunityRatings(_ rows: [CommunityRating]) {
        guard let data = try? JSONEncoder().encode(rows) else { return }
        try? data.write(to: communityCacheURL)
    }

    private static func mapCommunityRows(_ rows: [CommunityRating]) -> [UUID: (average: Double, count: Int)] {
        var result: [UUID: (average: Double, count: Int)] = [:]
        for row in rows {
            result[row.restaurantId] = (row.communityRating, row.communityRatingCount)
        }
        return result
    }

    /// Fetch the caller's rating for a specific restaurant.
    /// If `userId` is provided, queries by user_id; otherwise falls back to device_id (anon).
    func fetchMyRating(restaurantId: UUID, userId: UUID?) async throws -> Double? {
        let base = client
            .from("user_ratings")
            .select()
            .eq("restaurant_id", value: restaurantId.uuidString)

        let rows: [UserRatingRow]
        if let userId {
            rows = try await base
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
        } else {
            rows = try await base
                .eq("device_id", value: DeviceID.current)
                .is("user_id", value: nil)
                .execute()
                .value
        }
        return rows.first?.rating
    }

    /// Fetch all of the caller's ratings (used for Profile tab).
    func fetchAllMyRatings(userId: UUID?) async throws -> [UserRatingRow] {
        let base = client.from("user_ratings").select()
        if let userId {
            return try await base
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
        } else {
            return try await base
                .eq("device_id", value: DeviceID.current)
                .is("user_id", value: nil)
                .execute()
                .value
        }
    }

    /// Delete the caller's rating for a restaurant.
    func deleteRating(restaurantId: UUID, userId: UUID?) async throws {
        let base = client
            .from("user_ratings")
            .delete()
            .eq("restaurant_id", value: restaurantId.uuidString)

        if let userId {
            try await base.eq("user_id", value: userId.uuidString).execute()
        } else {
            try await base
                .eq("device_id", value: DeviceID.current)
                .is("user_id", value: nil)
                .execute()
        }
    }

    /// Delete ALL of the caller's ratings.
    func deleteAllRatings(userId: UUID?) async throws {
        let base = client.from("user_ratings").delete()
        if let userId {
            try await base.eq("user_id", value: userId.uuidString).execute()
        } else {
            try await base
                .eq("device_id", value: DeviceID.current)
                .is("user_id", value: nil)
                .execute()
        }
    }

    /// Submit or update the caller's rating.
    func submitRating(restaurantId: UUID, rating: Double, userId: UUID?) async throws {
        var row: [String: String] = [
            "restaurant_id": restaurantId.uuidString,
            "device_id": DeviceID.current,
            "rating": String(rating)
        ]
        let conflictKey: String
        if let userId {
            row["user_id"] = userId.uuidString
            conflictKey = "restaurant_id,user_id"
        } else {
            conflictKey = "restaurant_id,device_id"
        }
        try await client
            .from("user_ratings")
            .upsert(row, onConflict: conflictKey)
            .execute()
    }

    /// Claim this device's anonymous ratings for the given user.
    /// Conflict rule: for restaurants rated both anonymously on this device and already under the user account,
    /// the row with the newer `updated_at` wins; the loser is deleted.
    func migrateDeviceRatingsToUser(userId: UUID) async throws {
        let deviceRows: [UserRatingRow] = try await client
            .from("user_ratings")
            .select()
            .eq("device_id", value: DeviceID.current)
            .is("user_id", value: nil)
            .execute()
            .value

        guard !deviceRows.isEmpty else { return }

        let userRows: [UserRatingRow] = try await client
            .from("user_ratings")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        let userByRestaurant = Dictionary(uniqueKeysWithValues: userRows.map { ($0.restaurantId, $0) })

        for deviceRow in deviceRows {
            guard let deviceRowId = deviceRow.id else { continue }

            if let userRow = userByRestaurant[deviceRow.restaurantId], let userRowId = userRow.id {
                let deviceNewer = (deviceRow.updatedAt ?? .distantPast) > (userRow.updatedAt ?? .distantPast)
                if deviceNewer {
                    // User's row loses — delete it, then claim device row
                    try await client.from("user_ratings")
                        .delete()
                        .eq("id", value: userRowId.uuidString)
                        .execute()
                    try await client.from("user_ratings")
                        .update(["user_id": userId.uuidString])
                        .eq("id", value: deviceRowId.uuidString)
                        .execute()
                } else {
                    // User's row wins — delete the anon device duplicate
                    try await client.from("user_ratings")
                        .delete()
                        .eq("id", value: deviceRowId.uuidString)
                        .execute()
                }
            } else {
                // No conflict — claim the device row
                try await client.from("user_ratings")
                    .update(["user_id": userId.uuidString])
                    .eq("id", value: deviceRowId.uuidString)
                    .execute()
            }
        }
    }
}
