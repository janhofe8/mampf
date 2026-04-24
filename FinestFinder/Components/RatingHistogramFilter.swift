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
        VStack(spacing: 14) {
            header
            histogram
            Slider(value: $minimumRating, in: lo...hi, step: step)
                .tint(accentColor)
            if isFiltering {
                resetButton
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        .animation(.easeInOut(duration: 0.2), value: isFiltering)
        .onChange(of: minimumRating) {
            if minimumRating > 0 && minimumRating < lo {
                minimumRating = lo
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 4) {
                heroValue
                Text(String(format: String(localized: "ratingFilter.matchSummary"), matchCount, totalCount))
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)

            HStack {
                Spacer()
                Button { onDismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 26, height: 26)
                        .background(Color.gray.opacity(0.18), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var heroValue: some View {
        if isFiltering {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(minimumRating.formattedRating)
                    .monospacedDigit()
                Text("+")
            }
            .font(.system(size: 36, weight: .black, design: .rounded))
            .foregroundStyle(accentColor)
            .contentTransition(.numericText(value: minimumRating))
        } else {
            Text("ratingFilter.all")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Histogram

    private var histogram: some View {
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
        .frame(height: 60)
        .sensoryFeedback(.selection, trigger: minimumRating)
    }

    // MARK: - Reset

    private var resetButton: some View {
        Button {
            withAnimation { minimumRating = 0 }
        } label: {
            Label("ratingFilter.reset", systemImage: "arrow.counterclockwise")
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .foregroundStyle(.ffPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.ffPrimary.opacity(0.14), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
