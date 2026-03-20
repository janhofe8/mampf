import SwiftUI

extension Color {
    static let ffPrimary = Color(red: 0.45, green: 0.20, blue: 0.85)      // Purple
    static let ffSecondary = Color(red: 0.60, green: 1.0, blue: 0.20)     // Lime/Neon Green
    static let ffTertiary = Color(red: 0.15, green: 0.15, blue: 0.18)     // Dark Charcoal
    static let ffCardBackground = Color(red: 0.95, green: 0.95, blue: 0.97) // Light gray
    static let ffAmber = Color(red: 1.0, green: 0.75, blue: 0.0)          // Warm amber/yellow
    static let ffMuted = Color(red: 0.60, green: 0.60, blue: 0.63)        // Muted gray
    static let ffWeak = Color(red: 0.85, green: 0.25, blue: 0.25)        // Muted red

    /// Rating color based on personal rating (1-10 scale)
    static func ratingColor(for rating: Double) -> Color {
        switch rating {
        case _ where rating >= 9:   .ffPrimary    // 9, 9.5, 10 → purple (elite)
        case _ where rating >= 8:   .ffSecondary  // 8, 8.5 → lime (sehr gut)
        case _ where rating >= 7:   .ffAmber      // 7, 7.5 → amber (solide)
        case _ where rating >= 5:   .ffMuted      // 5, 5.5, 6, 6.5 → muted gray
        default:                    .ffWeak       // ≤4.5 → red
        }
    }
}

extension ShapeStyle where Self == Color {
    static var ffPrimary: Color { .ffPrimary }
    static var ffSecondary: Color { .ffSecondary }
    static var ffTertiary: Color { .ffTertiary }
}
