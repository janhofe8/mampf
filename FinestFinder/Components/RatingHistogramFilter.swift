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

    private var isFiltering: Bool { minimumRating > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("ratingFilter.minRating")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)

                Spacer()

                if isFiltering {
                    Text(minimumRating.formattedRating)
                        .font(.system(size: 32, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color.ratingColor(for: minimumRating))
                        .contentTransition(.numericText())
                } else {
                    Text("ratingFilter.all")
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 12) {
                    if isFiltering {
                        Button {
                            withAnimation { minimumRating = 0 }
                        } label: {
                            Text("ratingFilter.reset")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.ffPrimary)
                        }
                    }
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            // Tappable histogram bars
            GeometryReader { geo in
                let maxCount = max(histogramData.values.max() ?? 1, 1)
                let spacing: CGFloat = 2.5
                let barW = (geo.size.width - CGFloat(bucketValues.count - 1) * spacing) / CGFloat(bucketValues.count)
                let barAreaHeight = geo.size.height

                HStack(alignment: .bottom, spacing: spacing) {
                    ForEach(bucketValues, id: \.self) { bucket in
                        let count = histogramData[bucket] ?? 0
                        let frac = CGFloat(count) / CGFloat(maxCount)
                        let inRange = !isFiltering || bucket >= minimumRating

                        RoundedRectangle(cornerRadius: 3)
                            .fill(inRange ? Color.ratingColor(for: bucket) : Color.gray.opacity(0.22))
                            .frame(width: barW, height: max(4, frac * barAreaHeight))
                            .frame(maxHeight: .infinity, alignment: .bottom)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    minimumRating = (minimumRating == bucket) ? 0 : bucket
                                }
                            }
                    }
                }
            }
            .frame(height: 70)
            .sensoryFeedback(.selection, trigger: minimumRating)

            // Slider
            Slider(value: $minimumRating, in: lo...hi, step: step)
                .tint(.ffPrimary)

            // Match count
            Text("\(matchCount) \(String(localized: "ratingFilter.restaurants"))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        .onChange(of: minimumRating) {
            // Clamp slider value to valid range, but allow 0 (= no filter)
            if minimumRating > 0 && minimumRating < lo {
                minimumRating = lo
            }
        }
    }
}
