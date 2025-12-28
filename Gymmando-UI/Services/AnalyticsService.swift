import Foundation
import os.log
import SwiftUI

// MARK: - Analytics Events
enum AnalyticsEvent: String {
    // Auth Events
    case signInStarted = "sign_in_started"
    case signInCompleted = "sign_in_completed"
    case signInFailed = "sign_in_failed"
    case signUpStarted = "sign_up_started"
    case signUpCompleted = "sign_up_completed"
    case signUpFailed = "sign_up_failed"
    case signOut = "sign_out"
    case biometricAuthAttempted = "biometric_auth_attempted"
    case biometricAuthSuccess = "biometric_auth_success"
    case biometricAuthFailed = "biometric_auth_failed"

    // Session Events
    case sessionStarted = "session_started"
    case sessionEnded = "session_ended"
    case sessionDuration = "session_duration"
    case connectionFailed = "connection_failed"
    case connectionRetried = "connection_retried"

    // Onboarding Events
    case onboardingStarted = "onboarding_started"
    case onboardingCompleted = "onboarding_completed"
    case onboardingSkipped = "onboarding_skipped"
    case onboardingPageViewed = "onboarding_page_viewed"

    // Navigation Events
    case screenViewed = "screen_viewed"
    case settingsOpened = "settings_opened"
    case profileViewed = "profile_viewed"

    // Feature Events
    case featureUsed = "feature_used"
    case errorOccurred = "error_occurred"

    // Subscription Events (for future RevenueCat)
    case paywallViewed = "paywall_viewed"
    case purchaseStarted = "purchase_started"
    case purchaseCompleted = "purchase_completed"
    case purchaseFailed = "purchase_failed"
    case subscriptionRestored = "subscription_restored"
}

// MARK: - Analytics Protocol
protocol AnalyticsProvider {
    func track(event: AnalyticsEvent, parameters: [String: Any]?)
    func setUserProperty(_ value: String?, forName name: String)
    func setUserId(_ userId: String?)
}

// MARK: - Console Analytics Provider (Debug)
final class ConsoleAnalyticsProvider: AnalyticsProvider {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Gymmando", category: "Analytics")

    func track(event: AnalyticsEvent, parameters: [String: Any]?) {
        var message = "📊 Event: \(event.rawValue)"
        if let params = parameters {
            message += " | Params: \(params)"
        }
        logger.info("\(message)")
    }

    func setUserProperty(_ value: String?, forName name: String) {
        logger.info("📊 User Property: \(name) = \(value ?? "nil")")
    }

    func setUserId(_ userId: String?) {
        logger.info("📊 User ID: \(userId ?? "nil")")
    }
}

// MARK: - Firebase Analytics Provider (for production)
// Uncomment when Firebase Analytics is added
/*
import FirebaseAnalytics

final class FirebaseAnalyticsProvider: AnalyticsProvider {
    func track(event: AnalyticsEvent, parameters: [String: Any]?) {
        Analytics.logEvent(event.rawValue, parameters: parameters)
    }

    func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }

    func setUserId(_ userId: String?) {
        Analytics.setUserID(userId)
    }
}
*/

// MARK: - Analytics Service
final class AnalyticsService {
    static let shared = AnalyticsService()

    private var providers: [AnalyticsProvider] = []
    private let queue = DispatchQueue(label: "com.gymmando.analytics", qos: .utility)

    private init() {
        // Add console provider for debug builds
        #if DEBUG
        providers.append(ConsoleAnalyticsProvider())
        #endif

        // Add Firebase provider for production
        // Uncomment when Firebase Analytics is added
        // providers.append(FirebaseAnalyticsProvider())
    }

    // MARK: - Public API

    /// Track an analytics event
    func track(_ event: AnalyticsEvent, parameters: [String: Any]? = nil) {
        queue.async { [weak self] in
            self?.providers.forEach { provider in
                provider.track(event: event, parameters: parameters)
            }
        }
    }

    /// Set a user property
    func setUserProperty(_ value: String?, forName name: String) {
        queue.async { [weak self] in
            self?.providers.forEach { provider in
                provider.setUserProperty(value, forName: name)
            }
        }
    }

    /// Set the user ID for analytics
    func setUserId(_ userId: String?) {
        queue.async { [weak self] in
            self?.providers.forEach { provider in
                provider.setUserId(userId)
            }
        }
    }

    /// Add a custom analytics provider
    func addProvider(_ provider: AnalyticsProvider) {
        providers.append(provider)
    }

    // MARK: - Convenience Methods

    /// Track a screen view
    func trackScreen(_ screenName: String) {
        track(.screenViewed, parameters: ["screen_name": screenName])
    }

    /// Track an error
    func trackError(_ error: Error, context: String? = nil) {
        var params: [String: Any] = [
            "error_description": error.localizedDescription,
            "error_type": String(describing: type(of: error))
        ]
        if let context = context {
            params["context"] = context
        }
        track(.errorOccurred, parameters: params)
    }

    /// Track session duration
    func trackSessionDuration(_ seconds: Int) {
        track(.sessionDuration, parameters: [
            "duration_seconds": seconds,
            "duration_minutes": seconds / 60
        ])
    }
}

// MARK: - View Extension for Screen Tracking
struct ScreenTrackingModifier: ViewModifier {
    let screenName: String

    func body(content: Content) -> some View {
        content
            .onAppear {
                AnalyticsService.shared.trackScreen(screenName)
            }
    }
}

extension View {
    /// Track when this screen appears
    func trackScreen(_ name: String) -> some View {
        modifier(ScreenTrackingModifier(screenName: name))
    }
}
