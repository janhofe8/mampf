import SwiftUI
import CoreLocation

struct OnboardingView: View {
    @Environment(LocationManager.self) private var locationManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var page: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                welcomePage.tag(0)
                ratingPage.tag(1)
                locationPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            pageIndicator
                .padding(.top, 12)

            bottomButton
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .animation(.easeInOut(duration: 0.25), value: page)
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("🍽️")
                .font(.system(size: 96))
            Text("onboarding.welcome.title")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)
            Text("onboarding.welcome.subtitle")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var ratingPage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "star.circle.fill")
                .font(.system(size: 88))
                .foregroundStyle(Color.ffPrimary)
            Text("onboarding.rating.title")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)
            Text("onboarding.rating.subtitle")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 10) {
                ratingLegendRow(value: 9.5, label: "onboarding.rating.legend.great")
                ratingLegendRow(value: 8, label: "onboarding.rating.legend.good")
                ratingLegendRow(value: 7, label: "onboarding.rating.legend.ok")
                ratingLegendRow(value: 6, label: "onboarding.rating.legend.meh")
            }
            .padding(.top, 8)
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    private func ratingLegendRow(value: Double, label: LocalizedStringKey) -> some View {
        HStack(spacing: 14) {
            Text(value.formattedRating)
                .font(.system(size: 13, weight: .black).monospacedDigit())
                .foregroundStyle(Color.ratingTextColor(for: value))
                .frame(width: 32, height: 32)
                .background(Color.ratingColor(for: value), in: Circle())
            Text(label)
                .font(.subheadline.weight(.medium))
            Spacer()
        }
    }

    private var locationPage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "location.circle.fill")
                .font(.system(size: 88))
                .foregroundStyle(Color.ffPrimary)
            Text("onboarding.location.title")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)
            Text("onboarding.location.subtitle")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Controls

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Color.ffPrimary : Color.secondary.opacity(0.25))
                    .frame(width: i == page ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: page)
            }
        }
    }

    @ViewBuilder
    private var bottomButton: some View {
        switch page {
        case 0, 1:
            Button {
                withAnimation { page += 1 }
            } label: {
                Text("onboarding.next")
                    .primaryOnboardingStyle()
            }
        case 2:
            VStack(spacing: 10) {
                Button {
                    if locationManager.authorizationStatus == .notDetermined {
                        locationManager.requestPermission()
                    }
                    finish()
                } label: {
                    Text("onboarding.location.allow")
                        .primaryOnboardingStyle()
                }
                Button {
                    finish()
                } label: {
                    Text("onboarding.location.skip")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            }
        default:
            EmptyView()
        }
    }

    private func finish() {
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
    }
}

private extension Text {
    func primaryOnboardingStyle() -> some View {
        self
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.ffPrimary, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    OnboardingView()
        .environment(LocationManager())
}
