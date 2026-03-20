import SwiftUI

struct FilterSheetView: View {
    @Environment(FilterViewModel.self) private var filterVM
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var vm = filterVM

        NavigationStack {
            Form {
                Section("Rating: \(vm.minimumRating, specifier: "%.1f") – \(vm.maximumRating, specifier: "%.1f")") {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Min")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 30)
                            Slider(value: $vm.minimumRating, in: 0...10, step: 0.5)
                                .tint(.ffPrimary)
                                .onChange(of: vm.minimumRating) {
                                    if vm.minimumRating > vm.maximumRating {
                                        vm.maximumRating = vm.minimumRating
                                    }
                                }
                        }
                        HStack {
                            Text("Max")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 30)
                            Slider(value: $vm.maximumRating, in: 0...10, step: 0.5)
                                .tint(.ffPrimary)
                                .onChange(of: vm.maximumRating) {
                                    if vm.maximumRating < vm.minimumRating {
                                        vm.minimumRating = vm.maximumRating
                                    }
                                }
                        }
                    }
                }

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

            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        filterVM.clearFilters()
                    }
                    .foregroundStyle(.ffPrimary)
                    .disabled(!filterVM.hasActiveFilters)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
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
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color.ffPrimary : Color(.tertiarySystemFill), in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FilterSheetView()
        .environment(FilterViewModel())
}
