import SwiftUI

struct RestaurantListView: View {
    @Environment(FilterViewModel.self) private var filterVM
    @Environment(RestaurantStore.self) private var store
    @Environment(LocationManager.self) private var locationManager

    private var filtered: [Restaurant] {
        let base = showFavoritesOnly ? store.favorites : store.restaurants
        return filterVM.apply(to: base, userLocation: locationManager.lastLocation, communityRatings: store.communityRatings)
    }

    @State private var showingFilters = false
    @State private var showingSettings = false
    @State private var viewMode = 0 // 0 = cards, 1 = grid, 2 = list
    @State private var showFavoritesOnly = false

    private let compactColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        @Bindable var vm = filterVM

        ScrollView {
            switch viewMode {
            case 1:
                LazyVGrid(columns: compactColumns, spacing: 14) {
                    ForEach(filtered) { restaurant in
                        NavigationLink(value: restaurant) {
                            RestaurantCardView(
                                restaurant: restaurant,
                                isFavorite: store.isFavorite(restaurant),
                                onFavoriteTap: { store.toggleFavorite(restaurant) },
                                compact: true,
                                communityRating: store.communityRating(for: restaurant)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            case 2:
                LazyVStack(spacing: 0) {
                    ForEach(filtered) { restaurant in
                        NavigationLink(value: restaurant) {
                            listRow(for: restaurant)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 110)
                    }
                }
                .padding(.top, 8)
            default:
                LazyVStack(spacing: 16) {
                    ForEach(filtered) { restaurant in
                        NavigationLink(value: restaurant) {
                            RestaurantCardView(
                                restaurant: restaurant,
                                isFavorite: store.isFavorite(restaurant),
                                onFavoriteTap: { store.toggleFavorite(restaurant) },
                                communityRating: store.communityRating(for: restaurant)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .searchable(text: $vm.searchText, prompt: Text(String(format: String(localized: "search.restaurants"), store.restaurants.count)))
        .refreshable { await store.refresh() }
        .navigationTitle("MAMPF")
        .toolbarTitleDisplayMode(.large)
        .onAppear { applyBrandedNavBarAppearance() }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { showingSettings = true } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.ffPrimary)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showFavoritesOnly.toggle()
                    }
                } label: {
                    Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                        .foregroundStyle(showFavoritesOnly ? .red : .ffPrimary)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewMode = (viewMode + 1) % 3
                    }
                } label: {
                    Image(systemName: viewModeIcon)
                        .foregroundStyle(.ffPrimary)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(SortField.allCases) { field in
                        Button {
                            filterVM.selectSort(field)
                        } label: {
                            Label {
                                Text(field.displayName)
                            } icon: {
                                if filterVM.sortField == field {
                                    Image(systemName: field.supportsDirection
                                          ? (filterVM.sortAscending ? "chevron.up" : "chevron.down")
                                          : "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundStyle(.ffPrimary)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingFilters = true
                } label: {
                    Image(systemName: filterVM.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundStyle(.ffPrimary)
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheetView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .overlay {
            if filtered.isEmpty && !store.isLoading {
                ContentUnavailableView.search(text: filterVM.searchText)
            }
        }
        .overlay {
            if store.isLoading && store.restaurants.isEmpty {
                ProgressView("list.loading")
                    .tint(.ffPrimary)
            }
        }
    }
    private func listRow(for restaurant: Restaurant) -> some View {
        HStack(alignment: .center, spacing: 14) {
            // Thumbnail — fixed size container
            AsyncRestaurantImage(url: restaurant.imageUrl.flatMap(URL.init), cuisineIcon: restaurant.cuisineType.icon)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            // Name + Ratings + Meta
            VStack(alignment: .leading, spacing: 6) {
                Text(restaurant.name)
                    .font(.system(size: 18, weight: .bold))
                    .lineLimit(1)

                // Rating pills like card view
                HStack(spacing: 6) {
                    if let personal = restaurant.personalRating {
                        RatingPill(icon: "star.fill", value: personal.formattedRating, color: RatingSource.personal.color, textColor: .white)
                    }
                    if let cr = store.communityRating(for: restaurant) {
                        RatingPill(icon: "person.2.fill", value: String(format: "%.1f", cr.average), color: RatingSource.community.color, textColor: .black)
                    } else {
                        RatingPill(icon: "person.2.fill", value: "–", color: Color.gray.opacity(0.2), textColor: .secondary)
                    }
                    if let google = restaurant.googleRating {
                        RatingPill(icon: "globe", value: String(format: "%.1f", google), color: RatingSource.google.color, textColor: .white)
                    }
                }

                // Ort + Cuisine + Preis
                Text("\(restaurant.neighborhood.displayName) · \(restaurant.cuisineType.icon) \(restaurant.cuisineType.displayName) · \(restaurant.priceRange.label)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }




    private var viewModeIcon: String {
        switch viewMode {
        case 1: "list.bullet"
        case 2: "rectangle.grid.1x2"
        default: "square.grid.2x2"
        }
    }
}

#Preview {
    NavigationStack {
        RestaurantListView()
    }
    .environment(FilterViewModel())
    .environment(RestaurantStore())
    .environment(LocationManager())
}
