import SwiftUI

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = -1.5

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: phase * geo.size.width)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Skeleton Shapes

private struct SkeletonRect: View {
    var width: CGFloat? = nil
    var height: CGFloat = 14
    var radius: CGFloat = 6

    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(Color(.systemGray5))
            .frame(width: width, height: height)
    }
}

private struct SkeletonPill: View {
    var width: CGFloat = 52
    var height: CGFloat = 24

    var body: some View {
        Capsule()
            .fill(Color(.systemGray5))
            .frame(width: width, height: height)
    }
}

// MARK: - Skeleton Card (matches RestaurantCardView)

struct SkeletonCardView: View {
    var compact: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            RoundedRectangle(cornerRadius: compact ? 12 : 20)
                .fill(Color(.systemGray6))

            // Rating pills top-left
            if compact {
                SkeletonPill(width: 36, height: 20)
                    .padding(6)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    SkeletonPill(width: 60, height: 28)
                    SkeletonPill(width: 48, height: 22)
                    SkeletonPill(width: 48, height: 22)
                }
                .padding(12)
            }

            // Bottom text area
            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: compact ? 4 : 8) {
                    SkeletonRect(width: compact ? 70 : 180, height: compact ? 10 : 22, radius: 4)
                    if !compact {
                        SkeletonRect(width: 240, height: 12, radius: 4)
                    }
                }
                .padding(compact ? 8 : 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(height: compact ? 120 : 240)
        .clipShape(RoundedRectangle(cornerRadius: compact ? 12 : 20))
        .shimmer()
    }
}

// MARK: - Skeleton List Row (matches listRow)

struct SkeletonListRow: View {
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Thumbnail
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 8) {
                // Name
                SkeletonRect(width: 140, height: 16)

                // Rating pills
                HStack(spacing: 6) {
                    SkeletonPill(width: 48, height: 22)
                    SkeletonPill(width: 48, height: 22)
                    SkeletonPill(width: 48, height: 22)
                }

                // Meta
                SkeletonRect(width: 200, height: 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .shimmer()
    }
}
