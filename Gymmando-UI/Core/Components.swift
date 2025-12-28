import SwiftUI

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 60, weight: .light))
                .foregroundColor(Color.App.textTertiary)
                .accessibilityHidden(true)

            // Text content
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(title)
                    .font(DesignTokens.Typography.headlineSmall)
                    .foregroundColor(Color.App.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(Color.App.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Optional action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    HapticManager.shared.impact(style: .light)
                    action()
                }) {
                    Text(actionTitle)
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(width: 200)
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

// MARK: - Skeleton Loading View
struct SkeletonView: View {
    @State private var isAnimating = false
    let width: CGFloat?
    let height: CGFloat

    init(width: CGFloat? = nil, height: CGFloat = 20) {
        self.width = width
        self.height = height
    }

    var body: some View {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
            .fill(
                LinearGradient(
                    colors: [
                        Color.App.surface,
                        Color.App.backgroundTertiary,
                        Color.App.surface
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .mask(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 200 : -200)
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
            .accessibilityLabel("Loading")
    }
}

// MARK: - Skeleton Card
struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Header
            HStack {
                SkeletonView(width: 40, height: 40)
                    .cornerRadius(DesignTokens.Radius.full)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    SkeletonView(width: 120, height: 16)
                    SkeletonView(width: 80, height: 12)
                }
            }

            // Content lines
            SkeletonView(height: 14)
            SkeletonView(width: 200, height: 14)
        }
        .padding(DesignTokens.Spacing.md)
        .background(Color.App.surface)
        .cornerRadius(DesignTokens.Radius.lg)
    }
}

// MARK: - Loading Button
struct LoadingButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            if !isLoading {
                HapticManager.shared.impact(style: .medium)
                action()
            }
        }) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }

                Text(isLoading ? "Loading..." : title)
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(isLoading)
        .accessibilityLabel(isLoading ? "Loading" : title)
    }
}

// MARK: - Error State View
struct ErrorStateView: View {
    let title: String
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.App.error.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color.App.error)
            }

            // Text content
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(title)
                    .font(DesignTokens.Typography.headlineSmall)
                    .foregroundColor(Color.App.textPrimary)

                Text(message)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(Color.App.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Retry button
            if let retryAction = retryAction {
                Button(action: {
                    HapticManager.shared.impact(style: .medium)
                    retryAction()
                }) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(width: 160)
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(title). \(message). Double tap to retry.")
    }
}

// MARK: - Success State View
struct SuccessStateView: View {
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    @State private var showCheckmark = false

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Animated checkmark
            ZStack {
                Circle()
                    .fill(Color.App.success.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color.App.success)
                    .scaleEffect(showCheckmark ? 1 : 0)
            }

            // Text content
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(title)
                    .font(DesignTokens.Typography.headlineSmall)
                    .foregroundColor(Color.App.textPrimary)

                Text(message)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(Color.App.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    HapticManager.shared.impact(style: .light)
                    action()
                }) {
                    Text(actionTitle)
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(width: 200)
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showCheckmark = true
            }
            HapticManager.shared.notification(type: .success)
        }
    }
}

// MARK: - Pull to Refresh
struct RefreshableScrollView<Content: View>: View {
    let onRefresh: () async -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            content()
        }
        .refreshable {
            HapticManager.shared.impact(style: .light)
            await onRefresh()
        }
    }
}

// MARK: - Previews
#Preview("Empty State") {
    EmptyStateView(
        icon: "tray",
        title: "No Items",
        message: "You don't have any items yet. Add one to get started.",
        actionTitle: "Add Item",
        action: {}
    )
    .background(Color.App.background)
}

#Preview("Skeleton Card") {
    VStack(spacing: DesignTokens.Spacing.md) {
        SkeletonCard()
        SkeletonCard()
    }
    .padding()
    .background(Color.App.background)
}

#Preview("Error State") {
    ErrorStateView(
        title: "Something went wrong",
        message: "We couldn't load your data. Please try again.",
        retryAction: {}
    )
    .background(Color.App.background)
}

#Preview("Success State") {
    SuccessStateView(
        title: "Success!",
        message: "Your changes have been saved.",
        actionTitle: "Continue",
        action: {}
    )
    .background(Color.App.background)
}
