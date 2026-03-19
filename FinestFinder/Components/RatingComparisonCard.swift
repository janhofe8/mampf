import SwiftUI

struct RatingComparisonCard: View {
    let ratings: [Rating]

    private var sortedRatings: [Rating] {
        ratings.sorted { a, b in
            if a.source == .personal { return true }
            if b.source == .personal { return false }
            return a.source.displayName < b.source.displayName
        }
    }

    private var consensus: (average: Double, label: String)? {
        guard ratings.count >= 2 else { return nil }
        let normalized = ratings.map(\.normalized)
        let avg = normalized.reduce(0, +) / Double(normalized.count)
        let spread = (normalized.max() ?? 0) - (normalized.min() ?? 0)

        let label: String = switch spread {
        case ..<0.1: "Strong agreement"
        case 0.1..<0.2: "Mostly aligned"
        case 0.2..<0.3: "Some disagreement"
        default: "Divergent opinions"
        }

        return (avg, label)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ratings")
                .font(.headline)

            ForEach(sortedRatings, id: \.source) { rating in
                RatingBarView(rating: rating)
            }

            if let consensus {
                Divider()
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.secondary)
                    Text(consensus.label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(consensus.average * 100))%")
                        .font(.subheadline.monospacedDigit().bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    RatingComparisonCard(ratings: [
        Rating(source: .personal, value: 9.0),
        Rating(source: .google, value: 4.2, reviewCount: 832)
    ])
    .padding()
}
