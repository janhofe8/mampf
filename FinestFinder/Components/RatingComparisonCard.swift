import SwiftUI

struct RatingComparisonCard: View {
    let ratings: [Rating]

    private var sortedRatings: [Rating] {
        ratings.sorted { $0.source.sortOrder < $1.source.sortOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ratings.title")
                .font(.headline)

            ForEach(sortedRatings, id: \.source) { rating in
                RatingBarView(rating: rating)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    RatingComparisonCard(ratings: [
        Rating(source: .personal, value: 9.0),
        Rating(source: .google, value: 4.2, reviewCount: 832)
    ])
    .padding()
}
