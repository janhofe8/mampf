import SwiftUI

/// Minimalist rating slider (1-10 in 0.5 steps).
/// Renders a thin track + a simple coloured thumb that grows while dragging,
/// with a value callout that pops up above the thumb.
struct RatingSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double> = 1...10
    var step: Double = 0.5
    /// Fired when the user's drag starts/ends — use `false` to auto-save the final value.
    var onEditingChanged: (Bool) -> Void = { _ in }

    private let thumbSize: CGFloat = 22
    private let trackHeight: CGFloat = 5

    @GestureState private var isDragging = false

    private var isUnrated: Bool { value < range.lowerBound }

    /// Clamped to 0…1 so a pre-rated value of 0 doesn't push the thumb off the track.
    private var progress: CGFloat {
        let raw = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return max(0, min(1, CGFloat(raw)))
    }

    private var currentColor: Color {
        isUnrated ? Color.ffMuted : Color.ratingColor(for: value)
    }

    var body: some View {
        GeometryReader { geo in
            let usableWidth = max(0, geo.size.width - thumbSize)
            let thumbX = usableWidth * progress

            ZStack(alignment: .leading) {
                // Base track
                Capsule()
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: trackHeight)
                    .frame(maxHeight: .infinity)

                // Filled portion up to the thumb
                Capsule()
                    .fill(isUnrated ? AnyShapeStyle(Color.clear) : AnyShapeStyle(currentColor))
                    .frame(width: thumbX + thumbSize / 2, height: trackHeight)
                    .frame(maxHeight: .infinity)

                // Thumb — grows on drag for a tactile feel
                Circle()
                    .fill(currentColor)
                    .frame(width: thumbSize, height: thumbSize)
                    .scaleEffect(isDragging ? 1.35 : 1.0)
                    .shadow(color: currentColor.opacity(isDragging ? 0.4 : 0.2), radius: isDragging ? 6 : 2, y: 1)
                    .overlay(alignment: .bottom) {
                        // Callout shows current value while dragging
                        if isDragging && !isUnrated {
                            Text(value.formattedRating)
                                .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(currentColor, in: Capsule())
                                .offset(y: -34)
                                .transition(.scale(scale: 0.6).combined(with: .opacity))
                        }
                    }
                    .offset(x: thumbX)
                    .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.75), value: value)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isDragging)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isDragging) { _, state, _ in state = true }
                    .onChanged { drag in
                        let x = max(0, min(usableWidth, drag.location.x - thumbSize / 2))
                        let ratio = usableWidth > 0 ? Double(x / usableWidth) : 0
                        let raw = ratio * (range.upperBound - range.lowerBound) + range.lowerBound
                        let snapped = (raw / step).rounded() * step
                        value = max(range.lowerBound, min(range.upperBound, snapped))
                    }
                    .onEnded { _ in
                        onEditingChanged(false)
                    }
            )
            .onChange(of: isDragging) { _, dragging in
                if dragging { onEditingChanged(true) }
            }
        }
        .frame(height: 40)
        .sensoryFeedback(.selection, trigger: value)
    }
}

#Preview {
    struct Wrapper: View {
        @State var rating: Double = 0
        var body: some View {
            RatingSlider(value: $rating).padding()
        }
    }
    return Wrapper()
}
