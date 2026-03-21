import SwiftUI

enum RatingPillSize {
    case compact  // grid cards
    case small    // full cards
    case regular  // list view

    var iconSize: CGFloat {
        switch self {
        case .compact: 8
        case .small: 10
        case .regular: 10
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .compact: 12
        case .small: 14
        case .regular: 14
        }
    }

    var fontWeight: Font.Weight {
        switch self {
        case .compact: .black
        case .small: .bold
        case .regular: .black
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .compact: 6
        case .small: 10
        case .regular: 8
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .compact: 3
        case .small: 5
        case .regular: 4
        }
    }

    var iconFrameWidth: CGFloat? {
        switch self {
        case .compact: 10
        case .small: 14
        case .regular: nil
        }
    }

    var minWidth: CGFloat? {
        switch self {
        case .compact: 44
        default: nil
        }
    }

    var spacing: CGFloat {
        switch self {
        case .compact: 2
        case .small: 4
        case .regular: 3
        }
    }
}

struct RatingPill: View {
    let icon: String
    let value: String
    let color: Color
    let textColor: Color
    var size: RatingPillSize = .regular

    var body: some View {
        HStack(spacing: size.spacing) {
            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: size == .small ? .semibold : .bold))
                .frame(width: size.iconFrameWidth)
            Text(value)
                .font(.system(size: size.fontSize, weight: size.fontWeight).monospacedDigit())
        }
        .foregroundStyle(textColor)
        .frame(minWidth: size.minWidth)
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(color, in: Capsule())
    }
}

#Preview {
    VStack(spacing: 12) {
        HStack {
            RatingPill(icon: "star.fill", value: "9.5", color: .ffPrimary, textColor: .white, size: .compact)
            RatingPill(icon: "star.fill", value: "9.5", color: .ffPrimary, textColor: .white, size: .small)
            RatingPill(icon: "star.fill", value: "9.5", color: .ffPrimary, textColor: .white, size: .regular)
        }
    }
    .padding()
}
