import SwiftUI

// MARK: - Design Tokens
/// Centralized design system tokens for consistent UI

enum DesignTokens {
    // MARK: - Spacing
    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
        static let huge: CGFloat = 48
        static let massive: CGFloat = 64
    }

    // MARK: - Border Radius
    enum Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let full: CGFloat = 9999
    }

    // MARK: - Typography
    enum Typography {
        // Display
        static let displayLarge = Font.system(size: 57, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 45, weight: .bold, design: .rounded)
        static let displaySmall = Font.system(size: 36, weight: .bold, design: .rounded)

        // Headline
        static let headlineLarge = Font.system(size: 32, weight: .bold, design: .rounded)
        static let headlineMedium = Font.system(size: 28, weight: .semibold, design: .rounded)
        static let headlineSmall = Font.system(size: 24, weight: .semibold, design: .rounded)

        // Title
        static let titleLarge = Font.system(size: 22, weight: .semibold, design: .default)
        static let titleMedium = Font.system(size: 18, weight: .semibold, design: .default)
        static let titleSmall = Font.system(size: 14, weight: .semibold, design: .default)

        // Body
        static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)

        // Label
        static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
        static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
        static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)

        // Monospace (for status text)
        static let mono = Font.system(size: 12, weight: .semibold, design: .monospaced)
    }

    // MARK: - Animation
    enum Animation {
        static let quick: Double = 0.15
        static let standard: Double = 0.3
        static let slow: Double = 0.5
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
        static let smooth = SwiftUI.Animation.easeInOut(duration: standard)
    }

    // MARK: - Shadows
    enum Shadow {
        static let small = SwiftUI.Color.black.opacity(0.1)
        static let medium = SwiftUI.Color.black.opacity(0.15)
        static let large = SwiftUI.Color.black.opacity(0.2)

        static let smallRadius: CGFloat = 4
        static let mediumRadius: CGFloat = 8
        static let largeRadius: CGFloat = 16
    }

    // MARK: - Icon Sizes
    enum IconSize {
        static let xs: CGFloat = 16
        static let sm: CGFloat = 20
        static let md: CGFloat = 24
        static let lg: CGFloat = 32
        static let xl: CGFloat = 40
        static let xxl: CGFloat = 48
        static let huge: CGFloat = 64
        static let massive: CGFloat = 100
    }

    // MARK: - Touch Targets
    enum TouchTarget {
        /// Minimum touch target per Apple HIG
        static let minimum: CGFloat = 44
        static let comfortable: CGFloat = 48
        static let large: CGFloat = 56
    }
}

// MARK: - Color System
extension Color {
    enum App {
        // Primary
        static let primary = Color.orange
        static let primaryLight = Color.orange.opacity(0.8)
        static let primaryDark = Color(red: 0.85, green: 0.4, blue: 0.0)

        // Secondary
        static let secondary = Color.cyan
        static let secondaryLight = Color.cyan.opacity(0.8)

        // Accent
        static let accent = Color.purple

        // Semantic Colors
        static let success = Color.green
        static let warning = Color.yellow
        static let error = Color.red
        static let info = Color.blue

        // Backgrounds
        static let background = Color.black
        static let backgroundSecondary = Color(white: 0.08)
        static let backgroundTertiary = Color(white: 0.12)
        static let backgroundElevated = Color(white: 0.15)

        // Surface
        static let surface = Color(white: 0.15)
        static let surfaceHover = Color(white: 0.18)
        static let surfacePressed = Color(white: 0.12)

        // Text
        static let textPrimary = Color.white
        static let textSecondary = Color.gray
        static let textTertiary = Color(white: 0.5)
        static let textDisabled = Color(white: 0.3)

        // Borders
        static let border = Color(white: 0.2)
        static let borderFocused = Color.orange

        // Overlay
        static let overlay = Color.black.opacity(0.5)
        static let overlayLight = Color.black.opacity(0.3)
    }
}

// MARK: - View Extensions
extension View {
    /// Apply standard card styling
    func cardStyle() -> some View {
        self
            .background(Color.App.surface)
            .cornerRadius(DesignTokens.Radius.lg)
    }

    /// Apply elevated card styling
    func elevatedCardStyle() -> some View {
        self
            .background(Color.App.backgroundElevated)
            .cornerRadius(DesignTokens.Radius.lg)
            .shadow(color: DesignTokens.Shadow.medium, radius: DesignTokens.Shadow.mediumRadius)
    }

    /// Standard padding
    func standardPadding() -> some View {
        self.padding(DesignTokens.Spacing.md)
    }

    /// Screen padding (horizontal)
    func screenPadding() -> some View {
        self.padding(.horizontal, DesignTokens.Spacing.lg)
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignTokens.Typography.titleMedium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.TouchTarget.comfortable)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                    .fill(isEnabled ? Color.App.primary : Color.App.primary.opacity(0.5))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(DesignTokens.Animation.spring, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.shared.impact(style: .light)
                }
            }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignTokens.Typography.titleMedium)
            .foregroundColor(isEnabled ? Color.App.primary : Color.App.textDisabled)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.TouchTarget.comfortable)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                    .stroke(isEnabled ? Color.App.primary : Color.App.border, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(DesignTokens.Animation.spring, value: configuration.isPressed)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignTokens.Typography.titleMedium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.TouchTarget.comfortable)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                    .fill(Color.App.error)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(DesignTokens.Animation.spring, value: configuration.isPressed)
    }
}

// MARK: - Dynamic Type Support
extension DesignTokens.Typography {
    /// Returns a font that scales with Dynamic Type
    static func scaled(_ style: Font.TextStyle) -> Font {
        Font.system(style)
    }

    /// Custom scaled font that respects Dynamic Type
    static func customScaled(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        Font.system(size: size, weight: weight, design: design)
            .leading(.standard)
    }
}

// MARK: - Reduce Motion Modifier
struct MotionSensitiveModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let animation: Animation
    let value: AnyHashable

    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? nil : animation, value: value)
    }
}

extension View {
    /// Applies animation only when Reduce Motion is off
    func motionSensitiveAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        self.animation(animation, value: value)
            .transaction { transaction in
                if UIAccessibility.isReduceMotionEnabled {
                    transaction.animation = nil
                }
            }
    }

    /// Provides an alternative for reduced motion
    func withReducedMotionAlternative<V: View>(@ViewBuilder alternative: () -> V) -> some View {
        modifier(ReducedMotionAlternativeModifier(alternative: alternative))
    }
}

struct ReducedMotionAlternativeModifier<Alternative: View>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let alternative: () -> Alternative

    func body(content: Content) -> some View {
        if reduceMotion {
            alternative()
        } else {
            content
        }
    }
}

// MARK: - Reduce Transparency Modifier
extension View {
    /// Adjusts opacity based on Reduce Transparency setting
    func reduceTransparencyAware(defaultOpacity: Double = 0.8, reducedOpacity: Double = 1.0) -> some View {
        modifier(ReduceTransparencyModifier(defaultOpacity: defaultOpacity, reducedOpacity: reducedOpacity))
    }
}

struct ReduceTransparencyModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    let defaultOpacity: Double
    let reducedOpacity: Double

    func body(content: Content) -> some View {
        content
            .opacity(reduceTransparency ? reducedOpacity : defaultOpacity)
    }
}

// MARK: - Bold Text Modifier
extension View {
    /// Adjusts font weight based on Bold Text setting
    func boldTextAware() -> some View {
        modifier(BoldTextModifier())
    }
}

struct BoldTextModifier: ViewModifier {
    @Environment(\.legibilityWeight) var legibilityWeight

    func body(content: Content) -> some View {
        if legibilityWeight == .bold {
            content.fontWeight(.semibold)
        } else {
            content
        }
    }
}

// MARK: - Previews
#Preview("Design Tokens") {
    ScrollView {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Text("Gymmando")
                .font(DesignTokens.Typography.displaySmall)
                .foregroundColor(Color.App.textPrimary)

            Text("Design System Preview")
                .font(DesignTokens.Typography.bodyLarge)
                .foregroundColor(Color.App.textSecondary)

            Button("Primary Button") {}
                .buttonStyle(PrimaryButtonStyle())

            Button("Secondary Button") {}
                .buttonStyle(SecondaryButtonStyle())

            Button("Destructive Button") {}
                .buttonStyle(DestructiveButtonStyle())
        }
        .screenPadding()
    }
    .background(Color.App.background)
}
