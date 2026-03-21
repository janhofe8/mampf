import SwiftUI

struct RatingHistogramFilter: View {
    let restaurants: [Restaurant]
    @Binding var minimumRating: Double
    let matchCount: Int
    let onDismiss: () -> Void

    private let step: Double = 0.5
    private let hi: Double = 10.0

    private var lowestRating: Double {
        let ratings = restaurants.compactMap(\.personalRating)
        guard let min = ratings.min() else { return 5.0 }
        return (min / step).rounded(.down) * step
    }

    private var buckets: [Double] {
        stride(from: lowestRating, through: hi, by: step).map { $0 }
    }

    private var histogram: [Double: Int] {
        var counts: [Double: Int] = [:]
        for b in buckets { counts[b] = 0 }
        for r in restaurants {
            guard let rating = r.personalRating else { continue }
            let snapped = (rating / step).rounded() * step
            let clamped = max(lowestRating, min(hi, snapped))
            counts[clamped, default: 0] += 1
        }
        return counts
    }

    private var isFiltering: Bool { minimumRating > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 0) {
                Text("ratingFilter.minRating")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)

                Spacer()

                if isFiltering {
                    Text(fmtRating(minimumRating))
                        .font(.system(size: 44, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color.ratingColor(for: minimumRating))
                        .contentTransition(.numericText())
                } else {
                    Text("ratingFilter.all")
                        .font(.system(.title, design: .rounded, weight: .black))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button { onDismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                }
            }

            // Histogram bars
            GeometryReader { geo in
                let maxCount = max(histogram.values.max() ?? 1, 1)
                let spacing: CGFloat = 2.5
                let barW = (geo.size.width - CGFloat(buckets.count - 1) * spacing) / CGFloat(buckets.count)
                let barAreaHeight = geo.size.height - 18

                HStack(alignment: .bottom, spacing: spacing) {
                    ForEach(buckets, id: \.self) { bucket in
                        let count = histogram[bucket] ?? 0
                        let frac = CGFloat(count) / CGFloat(maxCount)
                        let inRange = !isFiltering || bucket >= minimumRating

                        VStack(spacing: 2) {
                            if count > 0 {
                                Text("\(count)")
                                    .font(.system(size: 11, weight: .black).monospacedDigit())
                                    .foregroundStyle(inRange ? .secondary : .quaternary)
                            }

                            RoundedRectangle(cornerRadius: 3)
                                .fill(inRange ? Color.ratingColor(for: bucket) : Color.gray.opacity(0.12))
                                .frame(width: barW, height: max(4, frac * barAreaHeight))
                                .animation(.easeInOut(duration: 0.15), value: minimumRating)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 85)

            // Slider
            Slider(value: $minimumRating, in: 0...hi, step: step) {
                EmptyView()
            } minimumValueLabel: {
                Text(fmtRating(lowestRating))
                    .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.tertiary)
            } maximumValueLabel: {
                Text(fmtRating(hi))
                    .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
                .tint(.ffPrimary)

            // Footer
            HStack {
                Text("\(matchCount) \(String(localized: "ratingFilter.restaurants"))")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.secondary)

                Spacer()

                if isFiltering {
                    Button {
                        withAnimation { minimumRating = 0 }
                    } label: {
                        Text("ratingFilter.reset")
                            .font(.body.weight(.bold))
                            .foregroundStyle(.ffPrimary)
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
    }

    private func fmtRating(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", v)
            : String(format: "%.1f", v)
    }
}
