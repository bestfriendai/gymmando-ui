import LocalAuthentication

/// Biometric authentication service
/// Note: This should ONLY be used in conjunction with Firebase session validation
/// Never use biometric success alone to grant app access
final class BiometricService {
    // MARK: - Properties
    private let context = LAContext()

    /// Check if biometrics are available on this device
    var canUseBiometrics: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Check if any authentication (biometrics or passcode) is available
    var canUseDeviceAuthentication: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    /// Get the type of biometric available
    var biometricType: LABiometryType {
        _ = canUseBiometrics // Trigger evaluation to populate biometryType
        return context.biometryType
    }

    /// Human-readable name for the biometric type
    var biometricTypeName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "Passcode"
        @unknown default:
            return "Biometrics"
        }
    }

    // MARK: - Authentication
    /// Authenticate using biometrics
    /// - Returns: Tuple of (success, error)
    func authenticate() async -> (Bool, Error?) {
        let reason = "Log in to Gymmando"

        // Create fresh context for each authentication attempt
        let context = LAContext()
        context.localizedCancelTitle = "Use Password"

        // Try biometrics first, fall back to passcode
        let policy: LAPolicy = canUseBiometrics
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication

        do {
            let success = try await context.evaluatePolicy(policy, localizedReason: reason)
            return (success, nil)
        } catch {
            return (false, error)
        }
    }

    /// Authenticate with a completion handler (legacy support)
    func authenticate(completion: @escaping (Bool, Error?) -> Void) {
        Task {
            let (success, error) = await authenticate()
            await MainActor.run {
                completion(success, error)
            }
        }
    }
}
