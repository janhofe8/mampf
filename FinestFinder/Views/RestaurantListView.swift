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
    @State private var viewMode = 0 // 0 = cards, 1 = grid, 2 = list
    @State private var showFavoritesOnly = false

    private let compactColumns = [
        GridItem(.flexible(), spacing: 10),
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
                        Divider().padding(.leading, 120)
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
        .searchable(text: $vm.searchText, prompt: "Search restaurants...")
        .refreshable { await store.refresh() }
        .navigationTitle("MAMPF")
        .toolbarTitleDisplayMode(.large)
        .onAppear { applyBrandedNavBarAppearance() }
        .toolbar {
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
        .overlay {
            if filtered.isEmpty && !store.isLoading {
                ContentUnavailableView.search(text: filterVM.searchText)
            }
        }
        .overlay {
            if store.isLoading && store.restaurants.isEmpty {
                ProgressView("Loading restaurants...")
                    .tint(.ffPrimary)
            }
        }
    }
    @ViewBuilder
    private func listRow(for restaurant: Restaurant) -> some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let urlString = restaurant.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        listThumbnailPlaceholder(for: restaurant)
                    default:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.quaternary)
                    }
                }
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                listThumbnailPlaceholder(for: restaurant)
            }

            // Name + Ratings
            VStack(alignment: .leading, spacing: 6) {
                Text(restaurant.name)
                    .font(.body.weight(.semibold))
                    .lineLimit(2)

                // Ratings: MAMPF → Community → Google
                HStack(spacing: 12) {
                    ratingLabel(
                        icon: "star.fill",
                        value: restaurant.personalRating,
                        color: RatingSource.personal.color
                    )
                    ratingLabel(
                        icon: "person.2.fill",
                        value: store.communityRating(for: restaurant)?.average,
                        color: RatingSource.community.color
                    )
                    ratingLabel(
                        icon: "globe",
                        value: restaurant.googleRating,
                        color: RatingSource.google.color,
                        maxScale: 5
                    )
                }

                Text(restaurant.neighborhood.displayName)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 4)

            // Metadaten rechts
            VStack(alignment: .trailing, spacing: 4) {
                Text(restaurant.cuisineType.icon)
                    .font(.system(size: 16))
                Text(restaurant.cuisineType.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(restaurant.priceRange.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func listThumbnailPlaceholder(for restaurant: Restaurant) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.quaternary)
            .frame(width: 90, height: 90)
            .overlay {
                Text(restaurant.cuisineType.icon)
                    .font(.largeTitle)
            }
    }

    private func ratingLabel(icon: String, value: Double?, color: Color, maxScale: Double = 10) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
            if let v = value {
                let fmt = maxScale <= 5
                    ? String(format: "%.1f", v)
                    : String(format: v.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", v)
                Text(fmt)
                    .font(.system(size: 15, weight: .black).monospacedDigit())
            } else {
                Text("–")
                    .font(.system(size: 15, weight: .bold).monospacedDigit())
                    .foregroundStyle(.quaternary)
            }
        }
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
