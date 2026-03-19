import SwiftUI

struct RatingBadge: View {
    let value: Double
    let maxValue: Double

    init(value: Double, maxValue: Double = 10) {
        self.value = value
        self.maxValue = maxValue
    }

    private var normalized: Double {
        value / maxValue
    }

    private var color: Color {
        ratingColor(for: normalized)
    }

    var body: some View {
        Text(formatted)
            .font(.caption.monospacedDigit().bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color, in: Capsule())
    }

    private var formatted: String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}

func ratingColor(for normalized: Double) -> Color {
    switch normalized {
    case 0.85...: .green
    case 0.7..<0.85: .teal
    case 0.5..<0.7: .orange
    default: .red
    }
}

#Preview {
    HStack {
        RatingBadge(value: 9.5)
        RatingBadge(value: 7.5)
        RatingBadge(value: 5.0)
        RatingBadge(value: 3.0)
        RatingBadge(value: 4.2, maxValue: 5)
    }
    .padding()
}
