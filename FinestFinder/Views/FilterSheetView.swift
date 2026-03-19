import SwiftUI

struct FilterSheetView: View {
    @Environment(FilterViewModel.self) private var filterVM
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var vm = filterVM

        NavigationStack {
            Form {
                Section("Cuisine") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
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

                Section("Neighborhood") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
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

                Section("Price Range") {
                    HStack(spacing: 12) {
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

                Section("Minimum Rating: \(vm.minimumRating, specifier: "%.1f")") {
                    Slider(value: $vm.minimumRating, in: 0...10, step: 0.5)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        filterVM.clearFilters()
                    }
                    .disabled(!filterVM.hasActiveFilters)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
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
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.tertiarySystemFill), in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FilterSheetView()
        .environment(FilterViewModel())
}
