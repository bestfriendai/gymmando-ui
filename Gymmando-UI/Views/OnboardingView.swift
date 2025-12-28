import SwiftUI

// MARK: - Onboarding Data Model
struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Meet Your AI Coach",
            subtitle: "Get personalized workout guidance through natural voice conversations",
            icon: "mic.fill",
            color: .orange
        ),
        OnboardingPage(
            title: "Train Smarter",
            subtitle: "Real-time form feedback and exercise recommendations tailored to your goals",
            icon: "figure.strengthtraining.traditional",
            color: .cyan
        ),
        OnboardingPage(
            title: "Track Progress",
            subtitle: "Monitor your fitness journey with detailed insights and achievements",
            icon: "chart.line.uptrend.xyaxis",
            color: .green
        )
    ]

    var body: some View {
        ZStack {
            Color.App.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(DesignTokens.Typography.labelLarge)
                    .foregroundColor(Color.App.textSecondary)
                    .padding(DesignTokens.Spacing.lg)
                    .accessibilityLabel("Skip onboarding")
                }

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? .none : .easeInOut, value: currentPage)

                // Page indicator
                HStack(spacing: DesignTokens.Spacing.xs) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.App.primary : Color.App.textTertiary)
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, DesignTokens.Spacing.xl)
                .accessibilityHidden(true)

                // Action button
                Button(action: handleButtonTap) {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.bottom, DesignTokens.Spacing.xxxl)
                .accessibilityLabel(currentPage == pages.count - 1 ? "Get started with Gymmando" : "Continue to next page")
            }
        }
    }

    private func handleButtonTap() {
        HapticManager.shared.impact(style: .light)
        if currentPage < pages.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        HapticManager.shared.notification(type: .success)
        withAnimation {
            hasCompletedOnboarding = true
        }
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            Spacer()

            // Icon with animated background
            ZStack {
                // Animated circles
                if !reduceMotion {
                    Circle()
                        .fill(page.color.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)

                    Circle()
                        .fill(page.color.opacity(0.2))
                        .frame(width: 150, height: 150)
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                }

                // Icon
                Image(systemName: page.icon)
                    .font(.system(size: 80, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [page.color, page.color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: page.color.opacity(0.5), radius: 20)
            }
            .accessibilityHidden(true)

            // Text content
            VStack(spacing: DesignTokens.Spacing.md) {
                Text(page.title)
                    .font(DesignTokens.Typography.headlineLarge)
                    .foregroundColor(Color.App.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(page.subtitle)
                    .font(DesignTokens.Typography.bodyLarge)
                    .foregroundColor(Color.App.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
            }

            Spacer()
            Spacer()
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
