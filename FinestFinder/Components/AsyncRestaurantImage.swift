import SwiftUI

struct AsyncRestaurantImage: View {
    let url: URL?
    let cuisineIcon: String
    var cornerRadius: CGFloat = 12
    var showProgress: Bool = false
    var gradient: Bool = false

    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholder
                default:
                    if showProgress {
                        placeholder.overlay { ProgressView().tint(.white) }
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius).fill(.quaternary)
                    }
                }
            }
        } else {
            placeholder
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        if gradient {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(colors: [.ffPrimary.opacity(0.8), .ffTertiary], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay {
                    Text(cuisineIcon)
                        .font(.title)
                        .opacity(0.5)
                }
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.quaternary)
                .overlay {
                    Text(cuisineIcon)
                        .font(.title)
                }
        }
    }
}
