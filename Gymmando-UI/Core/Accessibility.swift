import SwiftUI

// MARK: - Accessibility Extensions
extension View {
    /// Adds standard accessibility configuration for buttons
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }

    /// Adds standard accessibility configuration for headers
    func accessibleHeader(_ label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isHeader)
    }

    /// Adds accessibility for images
    func accessibleImage(label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isImage)
    }

    /// Hides element from accessibility
    func accessibilityHiddenCompletely() -> some View {
        self
            .accessibilityHidden(true)
            .accessibilityElement(children: .ignore)
    }

    /// Groups children for accessibility
    func accessibilityGrouped(label: String) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
    }

    /// Adds accessibility for text fields
    func accessibleTextField(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }

    /// Adds accessibility for status/live regions
    func accessibilityLiveRegion(_ label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Accessibility Announcements
enum AccessibilityAnnouncement {
    static func announce(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    static func announceScreenChange(_ message: String) {
        UIAccessibility.post(notification: .screenChanged, argument: message)
    }

    static func announceLayoutChange(_ message: String) {
        UIAccessibility.post(notification: .layoutChanged, argument: message)
    }
}

// MARK: - Dynamic Type Support
extension Font {
    /// Returns a font that scales with Dynamic Type
    static func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        return .system(size: size, weight: weight, design: design)
    }
}

// MARK: - Reduce Motion Support
struct ReduceMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let animation: Animation
    let reducedAnimation: Animation

    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? reducedAnimation : animation, value: UUID())
    }
}

extension View {
    /// Applies animation that respects Reduce Motion setting
    func reduceMotionAnimation(
        _ animation: Animation = .spring(),
        reduced: Animation = .linear(duration: 0.001)
    ) -> some View {
        modifier(ReduceMotionModifier(animation: animation, reducedAnimation: reduced))
    }
}

// MARK: - Accessibility Identifiers
enum AccessibilityID {
    // Login
    static let emailField = "login.email.field"
    static let passwordField = "login.password.field"
    static let signInButton = "login.signin.button"
    static let createAccountButton = "login.createaccount.button"
    static let googleSignInButton = "login.google.button"
    static let faceIDButton = "login.faceid.button"
    static let forgotPasswordButton = "login.forgotpassword.button"

    // Home
    static let startSessionButton = "home.startsession.button"
    static let settingsButton = "home.settings.button"
    static let statsSection = "home.stats.section"

    // AI Session
    static let endSessionButton = "session.end.button"
    static let connectionStatus = "session.status.label"
    static let audioVisualizer = "session.visualizer"
    static let closeButton = "session.close.button"

    // Settings
    static let signOutButton = "settings.signout.button"
    static let userProfile = "settings.profile.section"
}
