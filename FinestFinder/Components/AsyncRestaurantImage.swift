import SwiftUI

struct AsyncRestaurantImage: View {
    let url: URL?
    let cuisineIcon: String
    var cornerRadius: CGFloat = 12
    var showProgress: Bool = false
    var gradient: Bool = false

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        if let url {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .transition(.opacity.animation(.easeIn(duration: 0.15)))
                } else if failed {
                    placeholder
                } else if showProgress {
                    placeholder.overlay { ProgressView().tint(.white) }
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius).fill(.quaternary)
                }
            }
            .task(id: url) {
                if let loaded = await ImageCache.shared.image(for: url) {
                    image = loaded
                } else {
                    failed = true
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
