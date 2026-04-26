import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var page: Int = 0

    private var bgColor: Color {
        switch page {
        case 0: return .ffPrimary
        case 1: return .ffSecondary
        case 2: return Color(.systemGray5)
        case 3: return .ffAmber
        default: return .ffPrimary
        }
    }

    private var fgColor: Color {
        switch page {
        case 1, 2, 3: return .ffTertiary
        default: return .white
        }
    }

    private static let pageCount = 4

    var body: some View {
        ZStack {
            bgColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.35), value: page)
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    welcomePage.tag(0)
                    expertisePage.tag(1)
                    ratingPage.tag(2)
                    personalizePage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageIndicator
                    .padding(.top, 12)

                bottomButton
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: 28) {
            Spacer()
            HStack(spacing: 8) {
                Text("🌮")
                    .font(.system(size: 80))
                    .rotationEffect(.degrees(-12))
                Text("🍔")
                    .font(.system(size: 100))
                Text("🍝")
                    .font(.system(size: 80))
                    .rotationEffect(.degrees(12))
            }
            .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
            VStack(spacing: 18) {
                Text("onboarding.welcome.title")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundStyle(fgColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                Text("onboarding.welcome.subtitle")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(fgColor.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            Spacer()
        }
    }

    private var expertisePage: some View {
        VStack(spacing: 22) {
            Spacer()
            Text("onboarding.expertise.title")
                .font(.system(size: 46, weight: .black, design: .rounded))
                .foregroundStyle(fgColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            Text("onboarding.expertise.subtitle")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(fgColor.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 28)
            Spacer()
        }
    }

    private var personalizePage: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("onboarding.personalize.title")
                .font(.system(size: 46, weight: .black, design: .rounded))
                .foregroundStyle(fgColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            profilePreview
            Text("onboarding.personalize.subtitle")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(fgColor.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 28)
            Spacer()
        }
    }

    private var profilePreview: some View {
        VStack(spacing: 14) {
            Circle()
                .fill(Color.ffPrimary)
                .frame(width: 76, height: 76)
                .overlay {
                    Text("J")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
            HStack(spacing: 10) {
                miniStat(value: "12", labelKey: "profile.stats.rated")
                miniStat(value: "8 %", labelKey: "profile.stats.explored")
                miniStat(value: "🍝", labelKey: "profile.stats.favorite")
            }
            .padding(.horizontal, 20)
        }
    }

    private func miniStat(value: String, labelKey: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(fgColor)
                .lineLimit(1)
            Text(labelKey)
                .font(.caption.weight(.semibold))
                .foregroundStyle(fgColor.opacity(0.75))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 12))
    }

    private var ratingPage: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 14) {
                Text("onboarding.rating.title")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundStyle(fgColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                Text("onboarding.rating.subtitle")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(fgColor.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            HStack(spacing: 10) {
                sourcePill(icon: "star.fill", value: "9.5", source: .personal, label: "MAMPF")
                sourcePill(icon: "person.2.fill", value: "8.7", source: .community, label: "Community")
                sourcePill(icon: "globe", value: "4.4", source: .google, label: "Google")
            }
            .padding(.horizontal, 16)

            VStack(spacing: 12) {
                ratingLegendRow(value: 9.5, name: "rating.tier.mampf", range: "9+")
                ratingLegendRow(value: 8, name: "rating.tier.recommended", range: "8-8,5")
                ratingLegendRow(value: 7, name: "rating.tier.good", range: "7-7,5")
                ratingLegendRow(value: 6, name: "rating.tier.okay", range: "5-6,5")
                ratingLegendRow(value: 4, name: "rating.tier.avoid", range: "<5")
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private func sourcePill(icon: String, value: String, source: RatingSource, label: String) -> some View {
        let textColor: Color = source == .community ? .ffTertiary : .white
        return VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .black))
                Text(value)
                    .font(.system(size: 22, weight: .black, design: .rounded).monospacedDigit())
            }
            .foregroundStyle(textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(source.color, in: Capsule())
            .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
            Text(label)
                .font(.caption2.weight(.heavy))
                .foregroundStyle(fgColor.opacity(0.8))
                .textCase(.uppercase)
        }
    }

    private func ratingLegendRow(value: Double, name: LocalizedStringKey, range: String) -> some View {
        HStack(spacing: 14) {
            Text(value.formattedRating)
                .font(.system(size: 14, weight: .black).monospacedDigit())
                .foregroundStyle(Color.ratingTextColor(for: value))
                .frame(width: 36, height: 36)
                .background(Color.ratingColor(for: value), in: Circle())
            Text(name)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(fgColor)
            Spacer()
            Text(range)
                .font(.system(.subheadline, design: .rounded).weight(.semibold).monospacedDigit())
                .foregroundStyle(fgColor.opacity(0.7))
        }
    }

    // MARK: - Controls

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<Self.pageCount, id: \.self) { i in
                Capsule()
                    .fill(i == page ? fgColor : fgColor.opacity(0.3))
                    .frame(width: i == page ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: page)
            }
        }
    }

    private var bottomButton: some View {
        Button {
            if page == Self.pageCount - 1 {
                finish()
            } else {
                withAnimation { page += 1 }
            }
        } label: {
            Text(page == Self.pageCount - 1 ? "onboarding.getStarted" : "onboarding.next")
                .onboardingButtonStyle(bg: fgColor, fg: bgColor)
        }
    }

    private func finish() {
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
    }
}

private extension Text {
    func onboardingButtonStyle(bg: Color, fg: Color) -> some View {
        self
            .font(.system(.headline, design: .rounded).weight(.bold))
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(bg, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    OnboardingView()
}
