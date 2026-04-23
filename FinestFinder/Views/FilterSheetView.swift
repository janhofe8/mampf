import SwiftUI

struct FilterSheetView: View {
    @Environment(FilterViewModel.self) private var filterVM
    @Environment(RestaurantStore.self) private var store
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingSettings = false
    @State private var filteredCount = 0

    private var filterToken: Int {
        var h = Hasher()
        h.combine(store.restaurants.count)
        h.combine(filterVM.selectedCuisines)
        h.combine(filterVM.selectedNeighborhoods)
        h.combine(filterVM.selectedPriceRanges)
        h.combine(filterVM.minimumRating)
        h.combine(filterVM.showOpenOnly)
        return h.finalize()
    }

    private func refreshCount() {
        filteredCount = filterVM.apply(
            to: store.restaurants,
            userLocation: locationManager.lastLocation,
            communityRatings: store.communityRatings
        ).count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                Text("nav.filters")
                    .font(.title3.bold())
                HStack {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color(.tertiarySystemFill), in: Circle())
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color(.tertiarySystemFill), in: Circle())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
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
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 100)
            }
            .scrollDismissesKeyboard(.interactively)

            Spacer(minLength: 0)

            // Bottom bar
            VStack(spacing: 0) {
                Divider()
                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            filterVM.clearFilters()
                        }
                    } label: {
                        Text("nav.reset")
                            .font(.body)
                            .foregroundStyle(filterVM.hasActiveFilters ? .ffPrimary : .secondary)
                    }
                    .disabled(!filterVM.hasActiveFilters)

                    Spacer()

                    Button { dismiss() } label: {
                        Text(String(format: String(localized: "filter.showResults"), filteredCount))
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(Color.ffPrimary, in: Capsule())
                    }
                    .sensoryFeedback(.impact(weight: .medium), trigger: filteredCount)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(.bar)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .task { refreshCount() }
        .onChange(of: filterToken) { refreshCount() }
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
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

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
                    .minimumScaleFactor(0.75)
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.ffPrimary : Color(.tertiarySystemFill), in: Capsule())
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
