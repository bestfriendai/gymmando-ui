import Foundation
import os.log

// MARK: - Crash Reporting Service
/// Centralized crash and error reporting
///
/// ## Setup Instructions for Sentry
/// 1. Add Sentry SDK via SPM: https://github.com/getsentry/sentry-cocoa
/// 2. Configure in AppDelegate:
///    ```swift
///    import Sentry
///
///    SentrySDK.start { options in
///        options.dsn = "YOUR_SENTRY_DSN"
///        options.debug = true // Set to false in production
///        options.tracesSampleRate = 1.0
///        options.profilesSampleRate = 1.0
///        options.attachScreenshot = true
///        options.attachViewHierarchy = true
///        options.enableAutoSessionTracking = true
///    }
///    ```
/// 3. Identify users after authentication:
///    ```swift
///    CrashReportingService.shared.setUser(userId: user.uid, email: user.email)
///    ```
///
/// ## Alternative: Firebase Crashlytics
/// 1. Add Firebase Crashlytics via SPM or CocoaPods
/// 2. Configure in AppDelegate:
///    ```swift
///    import FirebaseCrashlytics
///
///    // After FirebaseApp.configure()
///    Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
///    ```
///
final class CrashReportingService {
    static let shared = CrashReportingService()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Gymmando", category: "CrashReporting")

    private init() {}

    // MARK: - Configuration

    /// Configure crash reporting service
    /// Call this in AppDelegate.didFinishLaunchingWithOptions
    func configure() {
        logger.info("Configuring crash reporting service")

        // TODO: Initialize Sentry
        /*
        SentrySDK.start { options in
            options.dsn = AppConfig.Sentry.dsn
            options.debug = AppConfig.environment == .development
            options.tracesSampleRate = 1.0
            options.profilesSampleRate = 1.0
            options.attachScreenshot = true
            options.attachViewHierarchy = true
            options.enableAutoSessionTracking = true
            options.enableAutoPerformanceTracing = true

            // Don't send in development
            options.beforeSend = { event in
                if AppConfig.environment == .development {
                    return nil
                }
                return event
            }
        }
        */

        // TODO: Or initialize Firebase Crashlytics
        /*
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        */
    }

    // MARK: - User Identification

    /// Set user information for crash reports
    func setUser(userId: String?, email: String? = nil, username: String? = nil) {
        logger.info("Setting crash reporting user: \(userId ?? "nil")")

        // TODO: Sentry implementation
        /*
        if let userId = userId {
            SentrySDK.setUser(User(userId: userId))
        } else {
            SentrySDK.setUser(nil)
        }
        */

        // TODO: Firebase Crashlytics implementation
        /*
        if let userId = userId {
            Crashlytics.crashlytics().setUserID(userId)
        }
        if let email = email {
            Crashlytics.crashlytics().setCustomValue(email, forKey: "email")
        }
        */
    }

    /// Clear user information (on sign out)
    func clearUser() {
        logger.info("Clearing crash reporting user")

        // TODO: Sentry implementation
        /*
        SentrySDK.setUser(nil)
        */

        // TODO: Firebase Crashlytics implementation
        /*
        Crashlytics.crashlytics().setUserID("")
        */
    }

    // MARK: - Error Reporting

    /// Capture a non-fatal error
    func captureError(_ error: Error, context: [String: Any]? = nil) {
        logger.error("Captured error: \(error.localizedDescription)")

        // Track in analytics
        AnalyticsService.shared.trackError(error, context: context?["context"] as? String)

        // TODO: Sentry implementation
        /*
        SentrySDK.capture(error: error) { scope in
            if let context = context {
                for (key, value) in context {
                    scope.setExtra(value: value, key: key)
                }
            }
        }
        */

        // TODO: Firebase Crashlytics implementation
        /*
        var userInfo = [String: Any]()
        if let context = context {
            userInfo = context
        }
        Crashlytics.crashlytics().record(error: error, userInfo: userInfo)
        */
    }

    /// Capture a message (for logging important events)
    func captureMessage(_ message: String, level: SeverityLevel = .info) {
        logger.log(level: level.osLogLevel, "\(message)")

        // TODO: Sentry implementation
        /*
        SentrySDK.capture(message: message) { scope in
            scope.setLevel(level.sentryLevel)
        }
        */

        // TODO: Firebase Crashlytics implementation
        /*
        Crashlytics.crashlytics().log(message)
        */
    }

    // MARK: - Breadcrumbs

    /// Add a breadcrumb for debugging crash context
    func addBreadcrumb(category: String, message: String, data: [String: Any]? = nil) {
        logger.debug("Breadcrumb [\(category)]: \(message)")

        // TODO: Sentry implementation
        /*
        let breadcrumb = Breadcrumb()
        breadcrumb.category = category
        breadcrumb.message = message
        breadcrumb.data = data
        SentrySDK.addBreadcrumb(breadcrumb)
        */
    }

    // MARK: - Custom Context

    /// Set custom context for crash reports
    func setContext(key: String, value: [String: Any]) {
        // TODO: Sentry implementation
        /*
        SentrySDK.configureScope { scope in
            scope.setContext(value: value, key: key)
        }
        */

        // TODO: Firebase Crashlytics implementation
        /*
        for (k, v) in value {
            Crashlytics.crashlytics().setCustomValue(v, forKey: "\(key).\(k)")
        }
        */
    }

    /// Set a tag for filtering in dashboard
    func setTag(key: String, value: String) {
        // TODO: Sentry implementation
        /*
        SentrySDK.configureScope { scope in
            scope.setTag(value: value, key: key)
        }
        */

        // TODO: Firebase Crashlytics implementation
        /*
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
        */
    }

    // MARK: - Performance Monitoring

    /// Start a performance transaction
    func startTransaction(name: String, operation: String) -> Any? {
        logger.debug("Starting transaction: \(name) [\(operation)]")

        // TODO: Sentry implementation
        /*
        return SentrySDK.startTransaction(name: name, operation: operation)
        */

        return nil
    }

    /// Finish a performance transaction
    func finishTransaction(_ transaction: Any?) {
        // TODO: Sentry implementation
        /*
        if let span = transaction as? Span {
            span.finish()
        }
        */
    }
}

// MARK: - Severity Level
enum SeverityLevel {
    case debug
    case info
    case warning
    case error
    case fatal

    var osLogLevel: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .default
        case .error:
            return .error
        case .fatal:
            return .fault
        }
    }

    // TODO: Add Sentry level conversion
    /*
    var sentryLevel: SentryLevel {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .warning
        case .error:
            return .error
        case .fatal:
            return .fatal
        }
    }
    */
}

// MARK: - Convenience Extensions
extension Error {
    /// Report this error to crash reporting
    func report(context: String? = nil) {
        var contextDict: [String: Any]?
        if let context = context {
            contextDict = ["context": context]
        }
        CrashReportingService.shared.captureError(self, context: contextDict)
    }
}
