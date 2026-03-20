import Foundation
import SwiftUI

enum RatingSource: String, Codable, CaseIterable, Identifiable {
    case personal
    case google
    case community

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .personal: "MAMPF"
        case .google: "Google"
        case .community: "Community"
        }
    }

    var icon: String {
        switch self {
        case .personal: "star.fill"
        case .google: "globe"
        case .community: "person.2.fill"
        }
    }

    var maxValue: Double {
        switch self {
        case .personal: 10
        case .google: 5
        case .community: 10
        }
    }

    var color: Color {
        switch self {
        case .personal: .ffPrimary
        case .community: .ffSecondary
        case .google: .gray
        }
    }

    /// Sort order: MAMPF → Community → Google
    var sortOrder: Int {
        switch self {
        case .personal: 0
        case .community: 1
        case .google: 2
        }
    }
}

struct Rating: Identifiable, Hashable {
    var id: String { source.rawValue }
    let source: RatingSource
    let value: Double?
    let reviewCount: Int?

    var normalized: Double {
        guard let value else { return 0 }
        return value / source.maxValue
    }

    init(source: RatingSource, value: Double?, reviewCount: Int? = nil) {
        self.source = source
        self.value = value
        self.reviewCount = reviewCount
    }
}
