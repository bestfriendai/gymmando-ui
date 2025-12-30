import SwiftUI

// MARK: - Toast Notification System
enum ToastType {
    case success
    case error
    case warning
    case info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return Color.App.success
        case .error: return Color.App.error
        case .warning: return Color.App.warning
        case .info: return Color.App.info
        }
    }
}

struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let type: ToastType
    let title: String
    let message: String?

    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.id == rhs.id
    }
}

class ToastManager: ObservableObject {
    static let shared = ToastManager()
    @Published var currentToast: ToastMessage?

    private init() {}

    func show(_ type: ToastType, title: String, message: String? = nil) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentToast = ToastMessage(type: type, title: title, message: message)
        }

        HapticManager.shared.notification(type: type == .success ? .success : type == .error ? .error : .warning)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.dismiss()
        }
    }

    func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            currentToast = nil
        }
    }
}

struct ToastView: View {
    let toast: ToastMessage
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: toast.type.icon)
                .font(.system(size: 22))
                .foregroundColor(toast.type.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(DesignTokens.Typography.titleSmall)
                    .foregroundColor(Color.App.textPrimary)

                if let message = toast.message {
                    Text(message)
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(Color.App.textSecondary)
                }
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.App.textTertiary)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(Color.App.backgroundElevated)
                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .stroke(toast.type.color.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(toast.type == .error ? "Error" : toast.type == .success ? "Success" : "Notification"): \(toast.title)")
    }
}

struct ToastModifier: ViewModifier {
    @ObservedObject var toastManager = ToastManager.shared

    func body(content: Content) -> some View {
        ZStack {
            content

            VStack {
                if let toast = toastManager.currentToast {
                    ToastView(toast: toast) {
                        toastManager.dismiss()
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.top, DesignTokens.Spacing.lg)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
                Spacer()
            }
        }
    }
}

extension View {
    func withToasts() -> some View {
        modifier(ToastModifier())
    }
}

// MARK: - Glassmorphism Card
struct GlassmorphicCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = DesignTokens.Spacing.lg

    init(padding: CGFloat = DesignTokens.Spacing.lg, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
}

// MARK: - Achievement Badge
struct AchievementBadge: View {
    let icon: String
    let title: String
    let isUnlocked: Bool
    var size: CGFloat = 80

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ZStack {
                // Glow effect for unlocked
                if isUnlocked {
                    Circle()
                        .fill(Color.yellow.opacity(0.3))
                        .frame(width: size * 1.2, height: size * 1.2)
                        .blur(radius: 10)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                }

                Circle()
                    .fill(
                        isUnlocked
                            ? LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.App.surface, Color.App.backgroundSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: size, height: size)

                Image(systemName: icon)
                    .font(.system(size: size * 0.4))
                    .foregroundColor(isUnlocked ? .white : Color.App.textTertiary)
            }

            Text(title)
                .font(DesignTokens.Typography.labelSmall)
                .foregroundColor(isUnlocked ? Color.App.textPrimary : Color.App.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: size + 20)
        .onAppear {
            if isUnlocked {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) badge, \(isUnlocked ? "unlocked" : "locked")")
    }
}

// MARK: - Streak Celebration View
struct StreakCelebrationView: View {
    let streakCount: Int
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showFlames = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: DesignTokens.Spacing.xl) {
                // Animated flames
                ZStack {
                    if showFlames && !reduceMotion {
                        ForEach(0..<5, id: \.self) { index in
                            FlameParticle(index: index)
                        }
                    }

                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.orange.opacity(0.5), .clear],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .scaleEffect(showContent ? 1 : 0.5)

                        Image(systemName: "flame.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange, .red],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .scaleEffect(showContent ? 1 : 0)
                    }
                }

                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text("\(streakCount) Day Streak! 🔥")
                        .font(DesignTokens.Typography.headlineLarge)
                        .foregroundColor(.white)

                    Text(streakMessage)
                        .font(DesignTokens.Typography.bodyLarge)
                        .foregroundColor(Color.App.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                Button {
                    HapticManager.shared.impact(style: .medium)
                    onDismiss()
                } label: {
                    Text("Keep It Going!")
                        .frame(width: 200)
                }
                .buttonStyle(PrimaryButtonStyle())
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            HapticManager.shared.notification(type: .success)

            if reduceMotion {
                showContent = true
                showFlames = true
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showContent = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showFlames = true
                }
            }
        }
    }

    private var streakMessage: String {
        switch streakCount {
        case 3: return "You're building momentum!"
        case 7: return "One week strong! Amazing!"
        case 14: return "Two weeks of dedication!"
        case 30: return "A full month! Incredible!"
        case 100: return "100 days! You're unstoppable!"
        default: return "Keep the fire burning!"
        }
    }
}

struct FlameParticle: View {
    let index: Int
    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: CGFloat.random(in: 20...40)))
            .foregroundColor(.orange.opacity(0.6))
            .offset(x: CGFloat.random(in: -50...50), y: offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: Double.random(in: 1...2))) {
                    offsetY = -CGFloat.random(in: 100...200)
                    opacity = 0
                }
            }
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 56

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(style: .medium)
            action()
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.App.primary, Color.App.primaryDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .shadow(color: Color.App.primary.opacity(0.4), radius: 8, y: 4)

                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel("Action button")
    }
}

// MARK: - Pulsing Dot Indicator
struct PulsingDot: View {
    var color: Color = Color.App.success
    var size: CGFloat = 8

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.4))
                .frame(width: size * 2, height: size * 2)
                .scaleEffect(isPulsing ? 1.5 : 1)
                .opacity(isPulsing ? 0 : 1)

            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    var animation: Animation = .linear(duration: 1.5).repeatForever(autoreverses: false)

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            Color.white.opacity(0.4),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(animation) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

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
