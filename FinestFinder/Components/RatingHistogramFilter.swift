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
    private let totalCount: Int

    init(restaurants: [Restaurant], minimumRating: Binding<Double>, matchCount: Int, onDismiss: @escaping () -> Void) {
        self._minimumRating = minimumRating
        self.matchCount = matchCount
        self.onDismiss = onDismiss

        let ratings = restaurants.compactMap(\.personalRating)
        self.totalCount = restaurants.count
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
    private var accentColor: Color { isFiltering ? Color.ratingColor(for: minimumRating) : .ffPrimary }

    var body: some View {
        VStack(spacing: 10) {
            header
            histogram
            Slider(value: $minimumRating, in: lo...hi, step: step)
                .tint(accentColor)
                .padding(.horizontal, 2)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
        .animation(.easeInOut(duration: 0.2), value: isFiltering)
        .onChange(of: minimumRating) {
            if minimumRating > 0 && minimumRating < lo {
                minimumRating = lo
            }
        }
    }

    // MARK: - Header (single compact line)

    private var header: some View {
        HStack(spacing: 10) {
            valuePill

            Text(String(format: String(localized: "ratingFilter.matchSummary"), matchCount, totalCount))
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button { onDismiss() } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(Color.gray.opacity(0.16), in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var valuePill: some View {
        if isFiltering {
            HStack(spacing: 1) {
                Text(minimumRating.formattedRating)
                    .monospacedDigit()
                Text("+")
            }
            .font(.system(.subheadline, design: .rounded, weight: .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(accentColor, in: Capsule())
            .contentTransition(.numericText(value: minimumRating))
        } else {
            Text("ratingFilter.all")
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.18), in: Capsule())
        }
    }

    // MARK: - Histogram

    private var histogram: some View {
        GeometryReader { geo in
            let maxCount = max(histogramData.values.max() ?? 1, 1)
            let spacing: CGFloat = 3
            let barW = (geo.size.width - CGFloat(bucketValues.count - 1) * spacing) / CGFloat(bucketValues.count)
            let barAreaHeight = geo.size.height

            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(bucketValues, id: \.self) { bucket in
                    let count = histogramData[bucket] ?? 0
                    let frac = CGFloat(count) / CGFloat(maxCount)
                    let inRange = !isFiltering || bucket >= minimumRating
                    let barColor = Color.ratingColor(for: bucket)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(
                            inRange
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [barColor.opacity(0.7), barColor],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                : AnyShapeStyle(Color.gray.opacity(0.22))
                        )
                        .frame(width: barW, height: max(4, frac * barAreaHeight))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .shadow(color: inRange ? barColor.opacity(0.25) : .clear, radius: 3, y: 1)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                minimumRating = (minimumRating == bucket) ? 0 : bucket
                            }
                        }
                }
            }
        }
        .frame(height: 48)
        .sensoryFeedback(.selection, trigger: minimumRating)
    }

}
