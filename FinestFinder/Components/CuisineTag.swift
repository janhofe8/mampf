import SwiftUI

struct CuisineTag: View {
    let cuisineType: CuisineType

    var body: some View {
        HStack(spacing: 4) {
            Text(cuisineType.icon)
                .font(.system(size: 14))
            Text(cuisineType.displayName)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.quaternary, in: Capsule())
    }
}

#Preview {
    HStack {
        CuisineTag(cuisineType: .burger)
        CuisineTag(cuisineType: .korean)
        CuisineTag(cuisineType: .oriental)
    }
    .padding()
}
