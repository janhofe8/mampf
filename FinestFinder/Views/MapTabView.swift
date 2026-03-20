import SwiftUI
import MapKit

struct MapTabView: View {
    @Environment(FilterViewModel.self) private var filterVM
    @Environment(RestaurantStore.self) private var store
    @State private var selectedRestaurant: Restaurant?
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 53.5575, longitude: 9.9620),
            span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
        )
    )
    @State private var isZoomedIn = false
    @State private var showingFilters = false
    @Environment(LocationManager.self) private var locationManager

    private var filtered: [Restaurant] {
        filterVM.apply(to: store.restaurants, userLocation: locationManager.lastLocation, communityRatings: store.communityRatings)
    }

    var body: some View {
        Map(position: $position) {
            UserAnnotation()

            ForEach(filtered) { restaurant in
                Annotation(restaurant.name, coordinate: restaurant.coordinate) {
                    mapPin(for: restaurant)
                        .onTapGesture {
                            selectedRestaurant = restaurant
                        }
                }
            }
        }
        .onMapCameraChange { context in
            let zoomed = context.region.span.latitudeDelta < 0.03
            if zoomed != isZoomedIn {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isZoomedIn = zoomed
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            VStack(spacing: 8) {
                Button {
                    if let location = locationManager.lastLocation {
                        withAnimation {
                            position = .region(MKCoordinateRegion(
                                center: location,
                                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                            ))
                        }
                    }
                } label: {
                    Image(systemName: "location.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.ffPrimary)
                        .frame(width: 44, height: 44)
                        .background(.regularMaterial, in: Circle())
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                }
                Button {
                    showingFilters = true
                } label: {
                    Image(systemName: filterVM.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.ffPrimary)
                        .frame(width: 44, height: 44)
                        .background(.regularMaterial, in: Circle())
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                }
            }
            .padding(.top, 60)
            .padding(.trailing, 12)
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheetView()
        }
        .navigationBarHidden(true)
        .sheet(item: $selectedRestaurant) { restaurant in
            NavigationStack {
                RestaurantDetailView(restaurant: restaurant)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done") { selectedRestaurant = nil }
                                .foregroundStyle(.ffPrimary)
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private func mapPin(for restaurant: Restaurant) -> some View {
        let color = annotationColor(for: restaurant)
        if isZoomedIn, let rating = restaurant.personalRating {
            Text(String(format: rating.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", rating))
                .font(.system(size: 11, weight: .black).monospacedDigit())
                .foregroundStyle(rating >= 7 && rating < 9 ? .black : .white)
                .frame(minWidth: 28, minHeight: 28)
                .background(color, in: Circle())
                .shadow(color: color.opacity(0.5), radius: 4)
        } else {
            Circle()
                .fill(color)
                .frame(width: 14, height: 14)
                .shadow(color: color.opacity(0.4), radius: 4)
        }
    }

    private func annotationColor(for restaurant: Restaurant) -> Color {
        guard let rating = restaurant.personalRating else { return .ffMuted }
        return .ratingColor(for: rating)
    }
}

#Preview {
    NavigationStack {
        MapTabView()
    }
    .environment(FilterViewModel())
    .environment(RestaurantStore())
    .environment(LocationManager())
}
