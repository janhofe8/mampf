import SwiftUI

struct FilterSheetView: View {
    @Environment(FilterViewModel.self) private var filterVM
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var vm = filterVM

        NavigationStack {
            Form {
                Section("filter.cuisine") {
                    let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
                    LazyVGrid(columns: cols, spacing: 8) {
                        ForEach(CuisineType.allCases) { cuisine in
                            FilterChip(
                                label: "\(cuisine.icon) \(cuisine.displayName)",
                                isSelected: filterVM.selectedCuisines.contains(cuisine)
                            ) {
                                filterVM.selectedCuisines.toggle(cuisine)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("filter.neighborhood") {
                    let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
                    LazyVGrid(columns: cols, spacing: 8) {
                        ForEach(Neighborhood.allCases) { hood in
                            FilterChip(
                                label: hood.displayName,
                                isSelected: filterVM.selectedNeighborhoods.contains(hood)
                            ) {
                                filterVM.selectedNeighborhoods.toggle(hood)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("filter.priceRange") {
                    let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
                    LazyVGrid(columns: cols, spacing: 8) {
                        ForEach(PriceRange.allCases) { price in
                            FilterChip(
                                label: price.label,
                                isSelected: filterVM.selectedPriceRanges.contains(price)
                            ) {
                                filterVM.selectedPriceRanges.toggle(price)
                            }
                        }
                    }
                }

            }
            .navigationTitle("nav.filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("nav.reset") {
                        filterVM.clearFilters()
                    }
                    .foregroundStyle(.ffPrimary)
                    .disabled(!filterVM.hasActiveFilters)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("nav.done") { dismiss() }
                        .foregroundStyle(.ffPrimary)
                }
            }
        }
    }
}

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.ffPrimary : Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FilterSheetView()
        .environment(FilterViewModel())
}
