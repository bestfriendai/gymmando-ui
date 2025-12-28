import UIKit

/// Centralized haptic feedback manager
final class HapticManager {
    static let shared = HapticManager()

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        // Prepare generators for immediate response
        prepareAll()
    }

    /// Prepare all generators for immediate haptic response
    func prepareAll() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactSoft.prepare()
        impactRigid.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }

    // MARK: - Impact Feedback
    enum ImpactStyle {
        case light
        case medium
        case heavy
        case soft
        case rigid
    }

    /// Trigger impact feedback
    func impact(style: ImpactStyle) {
        switch style {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        case .soft:
            impactSoft.impactOccurred()
        case .rigid:
            impactRigid.impactOccurred()
        }
    }

    /// Trigger impact with custom intensity (0.0 - 1.0)
    func impact(style: ImpactStyle, intensity: CGFloat) {
        switch style {
        case .light:
            impactLight.impactOccurred(intensity: intensity)
        case .medium:
            impactMedium.impactOccurred(intensity: intensity)
        case .heavy:
            impactHeavy.impactOccurred(intensity: intensity)
        case .soft:
            impactSoft.impactOccurred(intensity: intensity)
        case .rigid:
            impactRigid.impactOccurred(intensity: intensity)
        }
    }

    // MARK: - Selection Feedback
    /// Trigger selection feedback (for UI selection changes)
    func selection() {
        selectionGenerator.selectionChanged()
    }

    // MARK: - Notification Feedback
    /// Trigger notification feedback
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.notificationOccurred(type)
    }

    // MARK: - Convenience Methods
    /// Button tap feedback
    func buttonTap() {
        impact(style: .light)
    }

    /// Toggle switch feedback
    func toggle() {
        impact(style: .medium)
    }

    /// Success action completed
    func success() {
        notification(type: .success)
    }

    /// Error occurred
    func error() {
        notification(type: .error)
    }

    /// Warning feedback
    func warning() {
        notification(type: .warning)
    }
}

// MARK: - SwiftUI View Modifier
import SwiftUI

struct HapticButtonStyle: ButtonStyle {
    let hapticStyle: HapticManager.ImpactStyle

    init(style: HapticManager.ImpactStyle = .light) {
        self.hapticStyle = style
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.shared.impact(style: hapticStyle)
                }
            }
    }
}

extension View {
    /// Add haptic feedback to any view on tap
    func hapticFeedback(_ style: HapticManager.ImpactStyle = .light) -> some View {
        self.onTapGesture {
            HapticManager.shared.impact(style: style)
        }
    }
}
