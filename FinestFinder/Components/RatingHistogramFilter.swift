import SwiftUI

struct RatingHistogramFilter: View {
    @Binding var minimumRating: Double
    let matchCount: Int
    let onDismiss: () -> Void

    private let step: Double = 0.5
    private let hi: Double = 10.0
    private let lo: Double
    private let bucketValues: [Double]
    private let histogramData: [Double: Int]

    init(restaurants: [Restaurant], minimumRating: Binding<Double>, matchCount: Int, onDismiss: @escaping () -> Void) {
        self._minimumRating = minimumRating
        self.matchCount = matchCount
        self.onDismiss = onDismiss

        let ratings = restaurants.compactMap(\.personalRating)
        let minRating = ratings.min() ?? 5.0
        let lo = (minRating / step).rounded(.down) * step
        self.lo = lo

        let buckets = stride(from: lo, through: 10.0, by: step).map { $0 }
        self.bucketValues = buckets

        var counts: [Double: Int] = [:]
        for b in buckets { counts[b] = 0 }
        for r in restaurants {
            guard let rating = r.personalRating else { continue }
            let snapped = (rating / step).rounded() * step
            let clamped = max(lo, min(10.0, snapped))
            counts[clamped, default: 0] += 1
        }
        self.histogramData = counts
    }

    private var isFiltering: Bool { minimumRating > lo }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 0) {
                Text("ratingFilter.minRating")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)

                Spacer()

                if isFiltering {
                    Text(minimumRating.formattedRating)
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
                let maxCount = max(histogramData.values.max() ?? 1, 1)
                let spacing: CGFloat = 2.5
                let barW = (geo.size.width - CGFloat(bucketValues.count - 1) * spacing) / CGFloat(bucketValues.count)
                let barAreaHeight = geo.size.height - 18

                HStack(alignment: .bottom, spacing: spacing) {
                    ForEach(bucketValues, id: \.self) { bucket in
                        let count = histogramData[bucket] ?? 0
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
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 85)

            // Slider
            Slider(value: $minimumRating, in: lo...hi, step: step) {
                EmptyView()
            } minimumValueLabel: {
                Text(lo.formattedRating)
                    .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.tertiary)
            } maximumValueLabel: {
                Text(hi.formattedRating)
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
                        withAnimation { minimumRating = lo }
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
        .onAppear {
            if minimumRating < lo {
                minimumRating = lo
            }
        }
    }

}
