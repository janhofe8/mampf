import SwiftUI

struct FilterSheetView: View {
    @Environment(FilterViewModel.self) private var filterVM
    @Environment(RestaurantStore.self) private var store
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.dismiss) private var dismiss

    private var filteredCount: Int {
        filterVM.apply(to: store.restaurants, userLocation: locationManager.lastLocation, communityRatings: store.communityRatings).count
    }

    var body: some View {
        @Bindable var vm = filterVM

        NavigationStack {
            Form {
                FilterSection(title: "filter.cuisine", columns: 3, items: CuisineType.allCases, selection: filterVM.selectedCuisines) { cuisine in
                    "\(cuisine.icon) \(cuisine.displayName)"
                } onToggle: { cuisine in
                    filterVM.selectedCuisines.toggle(cuisine)
                }

                FilterSection(title: "filter.neighborhood", columns: 3, items: Neighborhood.allCases, selection: filterVM.selectedNeighborhoods) { hood in
                    hood.displayName
                } onToggle: { hood in
                    filterVM.selectedNeighborhoods.toggle(hood)
                }

                FilterSection(title: "filter.priceRange", columns: 4, items: PriceRange.allCases, selection: filterVM.selectedPriceRanges) { price in
                    price.label
                } onToggle: { price in
                    filterVM.selectedPriceRanges.toggle(price)
                }
            }
            .navigationTitle("nav.filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("nav.reset") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            filterVM.clearFilters()
                        }
                    }
                    .foregroundStyle(.ffPrimary)
                    .disabled(!filterVM.hasActiveFilters)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("nav.done") { dismiss() }
                        .foregroundStyle(.ffPrimary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button { dismiss() } label: {
                    Text(String(format: String(localized: "filter.showResults"), filteredCount))
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.ffPrimary, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .background(.bar)
                .sensoryFeedback(.impact(weight: .medium), trigger: filteredCount)
            }
        }
    }
}

private struct FilterSection<Item: Identifiable & Hashable>: View {
    let title: LocalizedStringKey
    let columns: Int
    let items: [Item]
    let selection: Set<Item>
    let label: (Item) -> String
    let onToggle: (Item) -> Void

    var body: some View {
        Section(title) {
            let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(items) { item in
                    FilterChip(
                        label: label(item),
                        isSelected: selection.contains(item)
                    ) {
                        onToggle(item)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                }
                Text(label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.caption)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.ffPrimary : Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    FilterSheetView()
        .environment(FilterViewModel())
        .environment(RestaurantStore())
        .environment(LocationManager())
}
