import SwiftUI

struct RatingBarView: View {
    let rating: Rating
    @State private var animatedProgress: CGFloat = 0

    private var barColor: Color { rating.source.color }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: rating.source.icon)
                    .foregroundStyle(barColor)
                    .frame(width: 20)
                Text(rating.source.displayName)
                    .font(.subheadline.weight(.medium))
                if rating.source == .google {
                    Text("Powered by Google")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                HStack(spacing: 4) {
                    if let value = rating.value {
                        Text("\(value, specifier: value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f") / \(Int(rating.source.maxValue))")
                            .font(.subheadline.monospacedDigit().bold())
                    } else {
                        Text("–")
                            .font(.subheadline.bold())
                            .foregroundStyle(.quaternary)
                    }

                    if let count = rating.reviewCount {
                        Text("(\(count))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 110, alignment: .trailing)
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
                            .frame(width: geo.size.width * animatedProgress)
                    }
                    .clipShape(Capsule())
            }
            .frame(height: 10)
            .onAppear {
                withAnimation(.spring(duration: 0.6, bounce: 0.2)) {
                    animatedProgress = rating.normalized
                }
            }
            .onChange(of: rating.normalized) { _, newValue in
                // Community ratings can arrive after first render — keep the bar in sync.
                withAnimation(.spring(duration: 0.5, bounce: 0.15)) {
                    animatedProgress = newValue
                }
            }
        }
        .accessibilityLabel("\(rating.source.displayName) Rating: \(rating.value ?? 0, specifier: "%.1f") von \(Int(rating.source.maxValue))")
    }
}

#Preview {
    VStack(spacing: 20) {
        RatingBarView(rating: Rating(source: .personal, value: 9.5))
        RatingBarView(rating: Rating(source: .google, value: 4.2, reviewCount: 832))
    }
    .padding()
}
