import SwiftUI

struct RestaurantListView: View {
    @Environment(FilterViewModel.self) private var filterVM
    @Environment(RestaurantStore.self) private var store

    private var filtered: [Restaurant] {
        filterVM.apply(to: store.restaurants)
    }

    @State private var showingFilters = false

    var body: some View {
        @Bindable var vm = filterVM

        List(filtered) { restaurant in
            NavigationLink(value: restaurant) {
                RestaurantRowView(restaurant: restaurant)
            }
        }
        .searchable(text: $vm.searchText, prompt: "Search restaurants...")
        .refreshable { await store.refresh() }
        .navigationTitle("Restaurants")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(SortOption.allCases) { option in
                        Button {
                            filterVM.sortOption = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if filterVM.sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingFilters = true
                } label: {
                    Image(systemName: filterVM.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheetView()
        }
        .overlay {
            if filtered.isEmpty && !store.isLoading {
                ContentUnavailableView.search(text: filterVM.searchText)
            }
        }
        .overlay {
            if store.isLoading && store.restaurants.isEmpty {
                ProgressView("Loading restaurants...")
            }
        }
    }
}

#Preview {
    NavigationStack {
        RestaurantListView()
    }
    .environment(FilterViewModel())
    .environment(RestaurantStore())
}
