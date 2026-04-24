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
        // Darker gray so white pill text stays legible (WCAG AA vs system .gray).
        case .google: Color(red: 0.38, green: 0.40, blue: 0.44)
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

/// Qualitative tier for a personal rating — mirrors the colour system.
/// Lets the UI describe a number ("8.0 = Empfehlung") so users align on scale intent.
enum RatingTier {
    case none, avoid, okay, good, recommended, mampf

    init(rating: Double) {
        switch rating {
        case let r where r <= 0: self = .none
        case let r where r < 5:  self = .avoid
        case let r where r < 7:  self = .okay
        case let r where r < 8:  self = .good
        case let r where r < 9:  self = .recommended
        default:                 self = .mampf
        }
    }

    var label: String? {
        switch self {
        case .none:        nil
        case .avoid:       String(localized: "rating.tier.avoid")
        case .okay:        String(localized: "rating.tier.okay")
        case .good:        String(localized: "rating.tier.good")
        case .recommended: String(localized: "rating.tier.recommended")
        case .mampf:       String(localized: "rating.tier.mampf")
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
