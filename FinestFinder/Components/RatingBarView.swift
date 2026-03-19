import SwiftUI

struct RatingBarView: View {
    let rating: Rating
    @State private var animatedWidth: CGFloat = 0

    private var barColor: Color {
        rating.source == .personal ? .ffSecondary : .ffPrimary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: rating.source.icon)
                    .foregroundStyle(barColor)
                Text(rating.source.displayName)
                    .font(.subheadline.weight(.medium))

                Spacer()

                Text("\(rating.value, specifier: rating.value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f") / \(Int(rating.source.maxValue))")
                    .font(.subheadline.monospacedDigit().bold())

                if let count = rating.reviewCount {
                    Text("(\(count))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            GeometryReader { geo in
                Capsule()
                    .fill(.quaternary)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [barColor.opacity(0.6), barColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: animatedWidth)
                    }
                    .clipShape(Capsule())
                    .onAppear {
                        withAnimation(.spring(duration: 0.6, bounce: 0.2)) {
                            animatedWidth = geo.size.width * rating.normalized
                        }
                    }
            }
            .frame(height: 10)
        }
        .accessibilityLabel("\(rating.source.displayName) Rating: \(rating.value, specifier: "%.1f") von \(Int(rating.source.maxValue))")
    }
}

#Preview {
    VStack(spacing: 20) {
        RatingBarView(rating: Rating(source: .personal, value: 9.5))
        RatingBarView(rating: Rating(source: .google, value: 4.2, reviewCount: 832))
    }
    .padding()
}
