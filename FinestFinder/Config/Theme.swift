import SwiftUI

extension Color {
    static let ffPrimary = Color(red: 0.45, green: 0.20, blue: 0.85)      // Purple
    static let ffSecondary = Color(red: 0.60, green: 1.0, blue: 0.20)     // Lime/Neon Green
    static let ffTertiary = Color(red: 0.15, green: 0.15, blue: 0.18)     // Dark Charcoal
    static let ffCardBackground = Color(red: 0.95, green: 0.95, blue: 0.97) // Light gray
    static let ffPurpleLight = Color(red: 0.60, green: 0.40, blue: 0.90)   // Lighter purple
    static let ffPurpleMuted = Color(red: 0.65, green: 0.55, blue: 0.80)  // Purple-grey
    static let ffMuted = Color(red: 0.60, green: 0.60, blue: 0.63)        // Muted gray
    static let ffWeak = Color(red: 0.85, green: 0.25, blue: 0.25)        // Muted red

    /// Rating color based on personal rating (1-10 scale) — purple family
    static func ratingColor(for rating: Double) -> Color {
        switch rating {
        case _ where rating >= 9:   .ffPrimary      // 9, 9.5, 10 → sattes purple (elite)
        case _ where rating >= 8:   .ffPurpleLight   // 8, 8.5 → helleres purple (sehr gut)
        case _ where rating >= 7:   .ffPurpleMuted   // 7, 7.5 → purple-grau (solide)
        case _ where rating >= 5:   .ffMuted         // 5, 5.5, 6, 6.5 → grau
        default:                    .ffWeak          // ≤4.5 → rot
        }
    }
}

func applyBrandedNavBarAppearance() {
    let purple = UIColor(Color.ffPrimary)
    let largeFont = UIFont.rounded(ofSize: 34, weight: .black)
    let inlineFont = UIFont.rounded(ofSize: 17, weight: .bold)

    let appearance = UINavigationBarAppearance()
    appearance.configureWithDefaultBackground()
    appearance.largeTitleTextAttributes = [.foregroundColor: purple, .font: largeFont]
    appearance.titleTextAttributes = [.foregroundColor: purple, .font: inlineFont]

    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
}

private extension UIFont {
    static func rounded(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            .withDesign(.rounded)?
            .addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]]) ?? UIFontDescriptor()
        return UIFont(descriptor: desc, size: size)
    }
}

extension ShapeStyle where Self == Color {
    static var ffPrimary: Color { .ffPrimary }
    static var ffSecondary: Color { .ffSecondary }
    static var ffTertiary: Color { .ffTertiary }
}
