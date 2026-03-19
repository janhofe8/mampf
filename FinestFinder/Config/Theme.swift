import SwiftUI

extension Color {
    static let ffPrimary = Color(red: 0.45, green: 0.20, blue: 0.85)      // Purple
    static let ffSecondary = Color(red: 0.60, green: 1.0, blue: 0.20)     // Lime/Neon Green
    static let ffTertiary = Color(red: 0.15, green: 0.15, blue: 0.18)     // Dark Charcoal
    static let ffCardBackground = Color(red: 0.95, green: 0.95, blue: 0.97) // Light gray
}

extension ShapeStyle where Self == Color {
    static var ffPrimary: Color { .ffPrimary }
    static var ffSecondary: Color { .ffSecondary }
    static var ffTertiary: Color { .ffTertiary }
}
