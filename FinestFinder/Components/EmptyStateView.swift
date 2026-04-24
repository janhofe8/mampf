import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    var actionTitle: LocalizedStringKey? = nil
    var action: (() -> Void)? = nil
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 10 : 16) {
            Image(systemName: icon)
                .font(.system(size: compact ? 36 : 52, weight: .regular))
                .foregroundStyle(Color.ffPrimary.opacity(0.7))
                .padding(compact ? 12 : 20)
                .background(Color.ffPrimary.opacity(0.08), in: Circle())

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(compact ? .subheadline : .headline, design: .rounded).weight(.semibold))
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(compact ? .caption : .subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.ffPrimary, in: Capsule())
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, compact ? 20 : 32)
    }
}

#Preview("Full") {
    EmptyStateView(
        icon: "magnifyingglass",
        title: "No spots found",
        message: "Try adjusting your filters to see more food spots.",
        actionTitle: "Reset filters",
        action: {}
    )
}

#Preview("Compact") {
    EmptyStateView(
        icon: "star.bubble",
        title: "No ratings yet",
        message: "Tap a spot and give it your rating.",
        compact: true
    )
}
