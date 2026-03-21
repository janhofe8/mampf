import SwiftUI

struct RatingComparisonCard: View {
    let ratings: [Rating]

    private var sortedRatings: [Rating] {
        ratings.sorted { $0.source.sortOrder < $1.source.sortOrder }
    }

    private var consensus: (average: Double, label: String)? {
        let withValues = ratings.filter { $0.value != nil }
        guard withValues.count >= 2 else { return nil }
        let normalized = withValues.map(\.normalized)
        let avg = normalized.reduce(0, +) / Double(normalized.count)
        let spread = (normalized.max() ?? 0) - (normalized.min() ?? 0)

        let label: String = switch spread {
        case ..<0.1: String(localized: "ratings.strongAgreement")
        case 0.1..<0.2: String(localized: "ratings.mostlyAligned")
        case 0.2..<0.3: String(localized: "ratings.someDisagreement")
        default: String(localized: "ratings.divergentOpinions")
        }

        return (avg, label)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ratings.title")
                .font(.headline)

            ForEach(sortedRatings, id: \.source) { rating in
                RatingBarView(rating: rating)
            }

            if let consensus {
                Divider()
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.ffPrimary)
                    Text(consensus.label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(consensus.average * 100))%")
                        .font(.subheadline.monospacedDigit().bold())
                        .foregroundStyle(.ffPrimary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
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
