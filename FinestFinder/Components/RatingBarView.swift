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
                    .frame(width: 90, alignment: .leading)

                Spacer()

                if let value = rating.value {
                    Text("\(value, specifier: value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f") / \(Int(rating.source.maxValue))")
                        .font(.subheadline.monospacedDigit().bold())
                        .lineLimit(1)
                        .fixedSize()
                } else {
                    Text("–")
                        .font(.subheadline.bold())
                        .foregroundStyle(.quaternary)
                        .fixedSize()
                }

                if let count = rating.reviewCount {
                    Text("(\(count))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 50, alignment: .trailing)
                } else {
                    Spacer().frame(width: 50)
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
