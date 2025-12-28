import Foundation
import FirebaseAuth
import Combine

/// Authentication state for the app
enum AuthState: Equatable {
    case loading
    case unauthenticated
    case authenticated(User)

    var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }

    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.unauthenticated, .unauthenticated):
            return true
        case (.authenticated(let lUser), .authenticated(let rUser)):
            return lUser.uid == rUser.uid
        default:
            return false
        }
    }
}

/// User model
struct AppUser {
    let uid: String
    let email: String?
    let displayName: String?
    let photoURL: URL?

    init(from firebaseUser: User) {
        self.uid = firebaseUser.uid
        self.email = firebaseUser.email
        self.displayName = firebaseUser.displayName
        self.photoURL = firebaseUser.photoURL
    }

    var firstName: String {
        if let displayName = displayName {
            return displayName.components(separatedBy: " ").first ?? displayName
        }
        if let email = email {
            return email.components(separatedBy: "@").first ?? ""
        }
        return ""
    }
}

/// Centralized authentication management
@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var authState: AuthState = .loading
    @Published private(set) var currentUser: AppUser?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    // MARK: - Private Properties
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let biometricService = BiometricService()

    // MARK: - Computed Properties
    var isAuthenticated: Bool {
        authState.isAuthenticated
    }

    var canUseBiometrics: Bool {
        biometricService.canUseBiometrics && hasStoredCredentials
    }

    private var hasStoredCredentials: Bool {
        // Check if user has signed in before and we have stored their UID
        UserDefaults.standard.string(forKey: "lastAuthenticatedUserUID") != nil
    }

    // MARK: - Initialization
    init() {
        setupAuthStateListener()
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Auth State Management
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    self?.authState = .authenticated(user)
                    self?.currentUser = AppUser(from: user)
                    // Store UID for biometric re-auth
                    UserDefaults.standard.set(user.uid, forKey: "lastAuthenticatedUserUID")
                } else {
                    self?.authState = .unauthenticated
                    self?.currentUser = nil
                }
            }
        }
    }

    // MARK: - Email/Password Authentication
    func signIn(email: String, password: String) async {
        guard validateInput(email: email, password: password) else { return }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            authState = .authenticated(result.user)
            currentUser = AppUser(from: result.user)
            HapticManager.shared.notification(type: .success)
        } catch {
            errorMessage = mapAuthError(error)
            HapticManager.shared.notification(type: .error)
        }

        isLoading = false
    }

    func createAccount(email: String, password: String) async {
        guard validateInput(email: email, password: password) else { return }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            authState = .authenticated(result.user)
            currentUser = AppUser(from: result.user)
            HapticManager.shared.notification(type: .success)
        } catch {
            errorMessage = mapAuthError(error)
            HapticManager.shared.notification(type: .error)
        }

        isLoading = false
    }

    // MARK: - Biometric Authentication
    /// Authenticates using biometrics ONLY if a valid Firebase session exists
    func authenticateWithBiometrics() async {
        guard canUseBiometrics else {
            // No stored credentials - user must log in with email/password first
            authState = .unauthenticated
            return
        }

        isLoading = true
        errorMessage = nil

        // First, check if Firebase still has a valid session
        guard let currentFirebaseUser = Auth.auth().currentUser else {
            // No Firebase session - biometrics can't help, need full login
            authState = .unauthenticated
            isLoading = false
            return
        }

        // Verify the stored UID matches current user
        let storedUID = UserDefaults.standard.string(forKey: "lastAuthenticatedUserUID")
        guard storedUID == currentFirebaseUser.uid else {
            // Mismatch - clear and require fresh login
            UserDefaults.standard.removeObject(forKey: "lastAuthenticatedUserUID")
            authState = .unauthenticated
            isLoading = false
            return
        }

        // Now authenticate with biometrics
        let (success, error) = await biometricService.authenticate()

        if success {
            // Biometric passed AND Firebase session is valid
            authState = .authenticated(currentFirebaseUser)
            currentUser = AppUser(from: currentFirebaseUser)
            HapticManager.shared.notification(type: .success)
        } else {
            // Biometric failed - show login screen but don't clear Firebase session
            // User can retry biometrics or use email/password
            if let error = error {
                errorMessage = error.localizedDescription
            }
            authState = .unauthenticated
            HapticManager.shared.notification(type: .error)
        }

        isLoading = false
    }

    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            authState = .unauthenticated
            currentUser = nil
            // Keep stored UID so user can use biometrics next time
            HapticManager.shared.notification(type: .success)
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
            HapticManager.shared.notification(type: .error)
        }
    }

    /// Sign out and clear all stored data
    func signOutCompletely() {
        signOut()
        UserDefaults.standard.removeObject(forKey: "lastAuthenticatedUserUID")
        UserDefaults.standard.removeObject(forKey: "hasSignedInBefore")
    }

    // MARK: - Password Reset
    func sendPasswordReset(email: String) async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            HapticManager.shared.notification(type: .success)
        } catch {
            errorMessage = mapAuthError(error)
            HapticManager.shared.notification(type: .error)
        }

        isLoading = false
    }

    // MARK: - Input Validation
    private func validateInput(email: String, password: String) -> Bool {
        if email.isEmpty {
            errorMessage = "Please enter your email"
            return false
        }

        if !isValidEmail(email) {
            errorMessage = "Please enter a valid email address"
            return false
        }

        if password.isEmpty {
            errorMessage = "Please enter your password"
            return false
        }

        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            return false
        }

        return true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }

    // MARK: - Error Mapping
    private func mapAuthError(_ error: Error) -> String {
        let nsError = error as NSError

        switch nsError.code {
        case AuthErrorCode.wrongPassword.rawValue:
            return "Incorrect password. Please try again."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Invalid email address format."
        case AuthErrorCode.userNotFound.rawValue:
            return "No account found with this email."
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "An account with this email already exists."
        case AuthErrorCode.weakPassword.rawValue:
            return "Password is too weak. Use at least 6 characters."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your connection."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many attempts. Please try again later."
        default:
            return error.localizedDescription
        }
    }
}
