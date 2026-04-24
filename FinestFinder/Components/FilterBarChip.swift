import SwiftUI

/// Pill-shaped filter chip shared between the map's and list's chip bar.
/// Renders an optional leading SF Symbol, label text, and optional trailing chevron.
/// Active state uses the brand primary; inactive uses a Material fill.
struct FilterBarChip: View {
    let icon: String
    let text: String
    let isActive: Bool
    var showChevron: Bool = true

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            if showChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isActive ? AnyShapeStyle(Color.ffPrimary) : AnyShapeStyle(.regularMaterial), in: Capsule())
        .foregroundStyle(isActive ? .white : .primary)
        .shadow(color: .black.opacity(isActive ? 0 : 0.08), radius: 4, y: 2)
    }
}

/// Entry-point chip that opens the full filter sheet.
/// Shows a purple numeric badge when filters are active.
struct FiltersEntryChip: View {
    let activeCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 11, weight: .semibold))
                Text("filter.filters")
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                if activeCount > 0 {
                    Text("\(activeCount)")
                        .font(.system(size: 11, weight: .bold).monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(minWidth: 16, minHeight: 16)
                        .padding(.horizontal, 3)
                        .background(Color.ffPrimary, in: Capsule())
                        .transition(.scale.combined(with: .opacity))
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .foregroundStyle(.primary)
            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        }
        .sensoryFeedback(.selection, trigger: activeCount)
    }
}
