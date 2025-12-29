import Foundation
import os.log

// MARK: - Subscription Tier
enum SubscriptionTier: String, CaseIterable {
    case free = "free"
    case premium = "premium"
    case pro = "pro"

    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .premium:
            return "Premium"
        case .pro:
            return "Pro"
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "3 AI sessions per day",
                "Basic workout guidance",
                "Community support"
            ]
        case .premium:
            return [
                "Unlimited AI sessions",
                "Advanced workout plans",
                "Progress tracking",
                "Priority support"
            ]
        case .pro:
            return [
                "Everything in Premium",
                "Personal training insights",
                "Custom workout programs",
                "1-on-1 support"
            ]
        }
    }
}

// MARK: - Subscription State
enum SubscriptionState: Equatable {
    case unknown
    case notSubscribed
    case subscribed(tier: SubscriptionTier, expiresAt: Date?)
    case expired
}

// MARK: - Subscription Service Protocol
protocol SubscriptionServiceProtocol {
    var currentState: SubscriptionState { get }
    var currentTier: SubscriptionTier { get }
    func checkSubscriptionStatus() async
    func purchase(productId: String) async throws
    func restorePurchases() async throws
}

// MARK: - Subscription Service
/// Subscription management using RevenueCat
///
/// ## Setup Instructions
/// 1. Add RevenueCat SDK via SPM: https://github.com/RevenueCat/purchases-ios
/// 2. Configure in AppDelegate:
///    ```swift
///    import RevenueCat
///
///    Purchases.logLevel = .debug
///    Purchases.configure(withAPIKey: "your_api_key")
///    ```
/// 3. Link user after Firebase auth:
///    ```swift
///    if let user = Auth.auth().currentUser {
///        Purchases.shared.logIn(user.uid) { customerInfo, created, error in
///            // Handle subscription state
///        }
///    }
///    ```
///
/// ## Product IDs (Configure in App Store Connect & RevenueCat)
/// - com.gymmando.premium.monthly
/// - com.gymmando.premium.yearly
/// - com.gymmando.pro.monthly
/// - com.gymmando.pro.yearly
///
@MainActor
final class SubscriptionService: ObservableObject, SubscriptionServiceProtocol {
    static let shared = SubscriptionService()

    @Published private(set) var currentState: SubscriptionState = .unknown
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Gymmando", category: "Subscription")

    var currentTier: SubscriptionTier {
        if case .subscribed(let tier, _) = currentState {
            return tier
        }
        return .free
    }

    var isSubscribed: Bool {
        if case .subscribed = currentState {
            return true
        }
        return false
    }

    private init() {
        // TODO: Initialize RevenueCat
        // Purchases.shared.delegate = self
    }

    // MARK: - RevenueCat Integration (Placeholder)

    /// Check current subscription status
    func checkSubscriptionStatus() async {
        isLoading = true

        // TODO: Implement with RevenueCat
        /*
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateState(from: customerInfo)
        } catch {
            logger.error("Failed to check subscription: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        */

        // Placeholder: Default to free tier
        currentState = .notSubscribed
        isLoading = false
    }

    /// Purchase a subscription product
    func purchase(productId: String) async throws {
        isLoading = true
        defer { isLoading = false }

        logger.info("Attempting purchase: \(productId)")
        AnalyticsService.shared.track(.purchaseStarted, parameters: ["product_id": productId])

        // TODO: Implement with RevenueCat
        /*
        do {
            let storeProduct = try await Purchases.shared.products([productId]).first
            guard let product = storeProduct else {
                throw SubscriptionError.productNotFound
            }

            let (_, customerInfo, _) = try await Purchases.shared.purchase(product: product)
            updateState(from: customerInfo)
            AnalyticsService.shared.track(.purchaseCompleted, parameters: ["product_id": productId])
        } catch {
            AnalyticsService.shared.track(.purchaseFailed, parameters: [
                "product_id": productId,
                "error": error.localizedDescription
            ])
            throw error
        }
        */

        throw SubscriptionError.notConfigured
    }

    /// Restore previous purchases
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        logger.info("Restoring purchases")

        // TODO: Implement with RevenueCat
        /*
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            updateState(from: customerInfo)
            AnalyticsService.shared.track(.subscriptionRestored)
        } catch {
            logger.error("Failed to restore: \(error.localizedDescription)")
            throw error
        }
        */

        throw SubscriptionError.notConfigured
    }

    /// Link RevenueCat with authenticated user
    func linkUser(userId: String) async {
        logger.info("Linking user: \(userId)")

        // TODO: Implement with RevenueCat
        /*
        do {
            let (customerInfo, _) = try await Purchases.shared.logIn(userId)
            updateState(from: customerInfo)
        } catch {
            logger.error("Failed to link user: \(error.localizedDescription)")
        }
        */
    }

    /// Unlink user on sign out
    func unlinkUser() async {
        logger.info("Unlinking user")

        // TODO: Implement with RevenueCat
        /*
        do {
            let customerInfo = try await Purchases.shared.logOut()
            updateState(from: customerInfo)
        } catch {
            logger.error("Failed to unlink user: \(error.localizedDescription)")
        }
        */

        currentState = .notSubscribed
    }

    // MARK: - Private Helpers

    /*
    private func updateState(from customerInfo: CustomerInfo) {
        if customerInfo.entitlements["pro"]?.isActive == true {
            currentState = .subscribed(
                tier: .pro,
                expiresAt: customerInfo.entitlements["pro"]?.expirationDate
            )
        } else if customerInfo.entitlements["premium"]?.isActive == true {
            currentState = .subscribed(
                tier: .premium,
                expiresAt: customerInfo.entitlements["premium"]?.expirationDate
            )
        } else {
            currentState = .notSubscribed
        }
    }
    */
}

// MARK: - Subscription Errors
enum SubscriptionError: LocalizedError {
    case notConfigured
    case productNotFound
    case purchaseFailed(String)
    case restoreFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Subscription service is not configured"
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed(let reason):
            return "Purchase failed: \(reason)"
        case .restoreFailed(let reason):
            return "Restore failed: \(reason)"
        }
    }
}

// MARK: - RevenueCat Delegate (Placeholder)
/*
extension SubscriptionService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            updateState(from: customerInfo)
        }
    }
}
*/
