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

    private var filtered: [Restaurant] {
        filterVM.apply(to: store.restaurants)
    }

    var body: some View {
        Map(position: $position) {
            ForEach(filtered) { restaurant in
                Annotation(restaurant.name, coordinate: restaurant.coordinate) {
                    Circle()
                        .fill(annotationColor(for: restaurant))
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(.white, lineWidth: 1.5))
                        .shadow(radius: 2)
                        .onTapGesture {
                            selectedRestaurant = restaurant
                        }
                }
            }
        }
        .navigationTitle("Map")
        .sheet(item: $selectedRestaurant) { restaurant in
            NavigationStack {
                RestaurantDetailView(restaurant: restaurant)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done") { selectedRestaurant = nil }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func annotationColor(for restaurant: Restaurant) -> Color {
        guard let rating = restaurant.personalRating else { return .gray }
        return ratingColor(for: rating / 10)
    }
}

#Preview {
    NavigationStack {
        MapTabView()
    }
    .environment(FilterViewModel())
    .environment(RestaurantStore())
}
