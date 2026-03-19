import SwiftUI

struct RatingBadge: View {
    let value: Double
    let maxValue: Double

    init(value: Double, maxValue: Double = 10) {
        self.value = value
        self.maxValue = maxValue
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.caption2)
            Text(formatted)
                .font(.caption.monospacedDigit().bold())
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ffSecondary, in: Capsule())
    }

    private var formatted: String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}

func ratingColor(for normalized: Double) -> Color {
    switch normalized {
    case 0.85...: .ffSecondary
    case 0.7..<0.85: .ffPrimary
    case 0.5..<0.7: .orange
    default: .red
    }
}

#Preview {
    HStack {
        RatingBadge(value: 9.5)
        RatingBadge(value: 7.5)
        RatingBadge(value: 4.2, maxValue: 5)
    }
    .padding()
}
