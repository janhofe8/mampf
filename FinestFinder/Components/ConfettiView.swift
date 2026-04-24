import SwiftUI

/// Lightweight SwiftUI confetti burst. Mount via `.overlay` and toggle `isActive`
/// to fire a one-shot animation. Auto-resets after the burst.
struct ConfettiView: View {
    @Binding var isActive: Bool
    var particleCount: Int = 35
    var duration: Double = 1.0

    @State private var particles: [Particle] = []

    fileprivate struct Particle: Identifiable {
        let id = UUID()
        let symbol: String
        let color: Color
        let startX: CGFloat  // 0..1
        let targetX: CGFloat // 0..1 (drift)
        let rotation: Double
        let scale: CGFloat
        let delay: Double
    }

    private static let symbols = ["star.fill", "heart.fill", "sparkle", "fork.knife", "circle.fill"]
    private static let palette: [Color] = [.ffPrimary, .ffSecondary, .yellow, .pink, .orange, .mint]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    ConfettiParticle(particle: p, size: geo.size, duration: duration)
                }
            }
            .allowsHitTesting(false)
        }
        .onChange(of: isActive) { _, newValue in
            if newValue { fire() }
        }
    }

    private func fire() {
        particles = (0..<particleCount).map { _ in
            Particle(
                symbol: Self.symbols.randomElement()!,
                color: Self.palette.randomElement()!,
                startX: .random(in: 0.3...0.7),
                targetX: .random(in: -0.1...1.1),
                rotation: .random(in: -360...360),
                scale: .random(in: 0.6...1.3),
                delay: .random(in: 0...0.15)
            )
        }
        Task {
            try? await Task.sleep(for: .seconds(duration + 0.2))
            particles.removeAll()
            isActive = false
        }
    }
}

private struct ConfettiParticle: View {
    let particle: ConfettiView.Particle
    let size: CGSize
    let duration: Double
    @State private var animate = false

    var body: some View {
        Image(systemName: particle.symbol)
            .font(.system(size: 14))
            .foregroundStyle(particle.color)
            .scaleEffect(particle.scale)
            .rotationEffect(.degrees(animate ? particle.rotation : 0))
            .position(
                x: size.width * (animate ? particle.targetX : particle.startX),
                y: animate ? size.height + 40 : -30
            )
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: duration).delay(particle.delay)) {
                    animate = true
                }
            }
    }
}
