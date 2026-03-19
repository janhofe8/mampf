import SwiftUI

struct CuisineTag: View {
    let cuisineType: CuisineType

    var body: some View {
        Text("\(cuisineType.icon) \(cuisineType.displayName)")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary, in: Capsule())
    }
}

#Preview {
    HStack {
        CuisineTag(cuisineType: .burger)
        CuisineTag(cuisineType: .korean)
        CuisineTag(cuisineType: .middleEastern)
    }
    .padding()
}
