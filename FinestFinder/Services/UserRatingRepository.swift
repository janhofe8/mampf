import Foundation
import Supabase

actor UserRatingRepository {

    struct UserRatingRow: Codable {
        let id: UUID?
        let restaurantId: UUID
        let deviceId: String
        let rating: Double
        let createdAt: Date?
        let updatedAt: Date?

        enum CodingKeys: String, CodingKey {
            case id
            case restaurantId = "restaurant_id"
            case deviceId = "device_id"
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

    /// Fetch community averages for all restaurants
    func fetchCommunityRatings() async throws -> [UUID: (average: Double, count: Int)] {
        let rows: [CommunityRating] = try await client
            .from("restaurant_community_ratings")
            .select()
            .execute()
            .value

        var result: [UUID: (average: Double, count: Int)] = [:]
        for row in rows {
            result[row.restaurantId] = (row.communityRating, row.communityRatingCount)
        }
        return result
    }

    /// Fetch the current device's rating for a specific restaurant
    func fetchMyRating(restaurantId: UUID) async throws -> Double? {
        let rows: [UserRatingRow] = try await client
            .from("user_ratings")
            .select()
            .eq("restaurant_id", value: restaurantId.uuidString)
            .eq("device_id", value: DeviceID.current)
            .execute()
            .value

        return rows.first?.rating
    }

    /// Delete the current device's rating
    func deleteRating(restaurantId: UUID) async throws {
        try await client
            .from("user_ratings")
            .delete()
            .eq("restaurant_id", value: restaurantId.uuidString)
            .eq("device_id", value: DeviceID.current)
            .execute()
    }

    /// Delete ALL ratings for the current device
    func deleteAllRatings() async throws {
        try await client
            .from("user_ratings")
            .delete()
            .eq("device_id", value: DeviceID.current)
            .execute()
    }

    /// Submit or update the current device's rating
    func submitRating(restaurantId: UUID, rating: Double) async throws {
        let row: [String: String] = [
            "restaurant_id": restaurantId.uuidString,
            "device_id": DeviceID.current,
            "rating": String(rating)
        ]

        try await client
            .from("user_ratings")
            .upsert(row, onConflict: "restaurant_id,device_id")
            .execute()
    }
}
