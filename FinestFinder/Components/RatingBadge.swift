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
            Text(value.formattedRating)
                .font(.caption.monospacedDigit().bold())
        }
        .foregroundStyle((value >= 7 && value < 9) ? Color.black : Color.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.ratingColor(for: value), in: Capsule())
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
