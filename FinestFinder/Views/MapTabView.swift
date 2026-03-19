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
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .shadow(color: .ffPrimary.opacity(0.3), radius: 4)
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
                                .foregroundStyle(.ffPrimary)
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func annotationColor(for restaurant: Restaurant) -> Color {
        guard let rating = restaurant.personalRating else { return .gray }
        switch rating {
        case 9...: return .ffSecondary          // 9, 9.5, 10 → neon green
        case 8..<9: return .ffPrimary           // 8, 8.5 → purple
        case 7..<8: return .orange              // 7, 7.5 → orange
        default: return .red                    // 6.5 and below → red
        }
    }
}

#Preview {
    NavigationStack {
        MapTabView()
    }
    .environment(FilterViewModel())
    .environment(RestaurantStore())
}
