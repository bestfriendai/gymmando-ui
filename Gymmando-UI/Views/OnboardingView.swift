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
    @State private var showSwipeHint = true
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
                // Top bar with back button and skip
                topBar

                // Progress bar
                progressBar
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                    .padding(.bottom, DesignTokens.Spacing.md)

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page, isFirstPage: index == 0, showSwipeHint: showSwipeHint && index == 0)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? .none : .easeInOut, value: currentPage)
                .onChange(of: currentPage) { _, _ in
                    showSwipeHint = false
                    HapticManager.shared.impact(style: .light)
                }

                // Interactive page indicator
                interactivePageIndicator
                    .padding(.bottom, DesignTokens.Spacing.lg)

                // Action buttons
                actionButtons
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                    .padding(.bottom, DesignTokens.Spacing.xxxl)
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            // Back button (hidden on first page)
            Button {
                withAnimation {
                    currentPage -= 1
                }
                HapticManager.shared.impact(style: .light)
            } label: {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                }
                .font(DesignTokens.Typography.labelLarge)
                .foregroundColor(Color.App.textSecondary)
            }
            .opacity(currentPage > 0 ? 1 : 0)
            .disabled(currentPage == 0)
            .accessibilityLabel("Go back")
            .accessibilityHidden(currentPage == 0)

            Spacer()

            Button("Skip") {
                completeOnboarding()
            }
            .font(DesignTokens.Typography.labelLarge)
            .foregroundColor(Color.App.textSecondary)
            .accessibilityLabel("Skip onboarding")
        }
        .padding(DesignTokens.Spacing.lg)
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.App.border)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Color.App.primary, Color.App.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: progressWidth(in: geometry.size.width), height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
        .frame(height: 4)
        .accessibilityLabel("Progress: step \(currentPage + 1) of \(pages.count)")
    }

    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        let progress = CGFloat(currentPage + 1) / CGFloat(pages.count)
        return totalWidth * progress
    }

    // MARK: - Interactive Page Indicator
    private var interactivePageIndicator: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(0..<pages.count, id: \.self) { index in
                Button {
                    withAnimation {
                        currentPage = index
                    }
                    HapticManager.shared.impact(style: .light)
                } label: {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(index == currentPage ? Color.App.primary : Color.App.textTertiary.opacity(0.5))
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
                .accessibilityLabel("Go to page \(index + 1)")
                .accessibilityAddTraits(index == currentPage ? .isSelected : [])
            }
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Button(action: handleButtonTap) {
                Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityLabel(currentPage == pages.count - 1 ? "Get started with Gymmando" : "Continue to next page")

            // Page count text
            Text("\(currentPage + 1) of \(pages.count)")
                .font(DesignTokens.Typography.labelSmall)
                .foregroundColor(Color.App.textTertiary)
                .accessibilityHidden(true)
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
    var isFirstPage: Bool = false
    var showSwipeHint: Bool = false
    @State private var isAnimating = false
    @State private var swipeHintOffset: CGFloat = 0
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

            // Swipe hint (only on first page)
            if showSwipeHint && !reduceMotion {
                swipeHintView
            }

            Spacer()
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
                if showSwipeHint {
                    withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                        swipeHintOffset = 10
                    }
                }
            }
        }
    }

    // MARK: - Swipe Hint View
    private var swipeHintView: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Text("Swipe to explore")
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(Color.App.textTertiary)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.App.textTertiary)
                .offset(x: swipeHintOffset)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(Color.App.surface.opacity(0.5))
        .cornerRadius(DesignTokens.Radius.full)
        .accessibilityLabel("Swipe left to see more pages")
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
