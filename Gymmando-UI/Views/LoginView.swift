import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import GoogleSignInSwift
import LocalAuthentication

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showForgotPassword = false
    @State private var isCreateMode = false
    @FocusState private var focusedField: Field?

    private let biometricService = BiometricService()

    enum Field {
        case email, password
    }

    // MARK: - Password Strength
    private var passwordStrength: PasswordStrength {
        PasswordStrength.evaluate(password)
    }

    var body: some View {
        ZStack {
            // Background
            Color.App.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xxl) {
                    Spacer().frame(height: DesignTokens.Spacing.huge)

                    // Logo and Title
                    headerSection

                    Spacer().frame(height: DesignTokens.Spacing.lg)

                    // Login Form
                    formSection

                    // Divider
                    dividerSection

                    // Social Login
                    socialLoginSection

                    // Biometric Option
                    if authViewModel.canUseBiometrics {
                        biometricSection
                    }

                    Spacer()
                }
                .screenPadding()
            }
            .scrollDismissesKeyboard(.interactively)

            // Loading Overlay
            if authViewModel.isLoading {
                loadingOverlay
            }
        }
        .onAppear {
            attemptBiometricAuth()
        }
        .alert("Reset Password", isPresented: $showForgotPassword) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
            Button("Cancel", role: .cancel) {}
            Button("Send Reset Link") {
                Task {
                    await authViewModel.sendPasswordReset(email: email)
                }
            }
        } message: {
            Text("Enter your email to receive a password reset link.")
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .cornerRadius(DesignTokens.Radius.xl)
                .shadow(color: Color.App.primary.opacity(0.3), radius: 20)
                .accessibilityLabel("Gymmando logo")

            Text("Gymmando")
                .font(DesignTokens.Typography.displaySmall)
                .foregroundColor(Color.App.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("Your AI Fitness Coach")
                .font(DesignTokens.Typography.bodyLarge)
                .foregroundColor(Color.App.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Gymmando, Your AI Fitness Coach")
    }

    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Mode Picker (Sign In / Create Account)
            modePicker

            // Email Field
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Email")
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(Color.App.textSecondary)
                    .accessibilityHidden(true)

                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(Color.App.textTertiary)
                        .frame(width: DesignTokens.IconSize.md)
                        .accessibilityHidden(true)

                    TextField("your@email.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .password
                        }
                        .accessibilityLabel("Email address")
                        .accessibilityHint(isCreateMode ? "Enter your email to create an account" : "Enter your email to sign in")
                        .accessibilityIdentifier(AccessibilityID.emailField)
                }
                .padding(DesignTokens.Spacing.md)
                .background(Color.App.surface)
                .cornerRadius(DesignTokens.Radius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .stroke(
                            focusedField == .email ? Color.App.primary : Color.App.border,
                            lineWidth: focusedField == .email ? 2 : 1
                        )
                )
            }

            // Password Field
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Password")
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(Color.App.textSecondary)

                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(Color.App.textTertiary)
                        .frame(width: DesignTokens.IconSize.md)

                    Group {
                        if showPassword {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }
                    }
                    .textContentType(isCreateMode ? .newPassword : .password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit {
                        handleSubmit()
                    }

                    Button {
                        showPassword.toggle()
                        HapticManager.shared.impact(style: .light)
                    } label: {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(Color.App.textTertiary)
                    }
                    .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                    .accessibilityHint("Double tap to toggle password visibility")
                }
                .padding(DesignTokens.Spacing.md)
                .background(Color.App.surface)
                .cornerRadius(DesignTokens.Radius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .stroke(
                            focusedField == .password ? Color.App.primary : Color.App.border,
                            lineWidth: focusedField == .password ? 2 : 1
                        )
                )

                // Password Strength Indicator (only in create mode)
                if isCreateMode && !password.isEmpty {
                    passwordStrengthView
                }
            }

            // Forgot Password (only in sign in mode)
            if !isCreateMode {
                HStack {
                    Spacer()
                    Button("Forgot Password?") {
                        showForgotPassword = true
                        HapticManager.shared.impact(style: .light)
                    }
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(Color.App.primary)
                    .accessibilityLabel("Forgot password")
                    .accessibilityHint("Double tap to reset your password")
                    .accessibilityIdentifier(AccessibilityID.forgotPasswordButton)
                }
            }

            // Error Message
            if let errorMessage = authViewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color.App.error)
                        .accessibilityHidden(true)
                    Text(errorMessage)
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(Color.App.error)
                }
                .padding(DesignTokens.Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(Color.App.error.opacity(0.1))
                .cornerRadius(DesignTokens.Radius.sm)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Error: \(errorMessage)")
                .accessibilityAddTraits(.isStaticText)
            }

            // Primary Action Button
            Button(action: handleSubmit) {
                Text(isCreateMode ? "Create Account" : "Sign In")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(email.isEmpty || password.isEmpty || (isCreateMode && passwordStrength == .weak))
            .accessibilityLabel(isCreateMode ? "Create account" : "Sign in")
            .accessibilityHint(email.isEmpty || password.isEmpty ? "Enter email and password first" : "Double tap to \(isCreateMode ? "create account" : "sign in")")
            .accessibilityIdentifier(isCreateMode ? AccessibilityID.createAccountButton : AccessibilityID.signInButton)
        }
    }

    // MARK: - Mode Picker
    private var modePicker: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCreateMode = false
                }
                HapticManager.shared.impact(style: .light)
            } label: {
                Text("Sign In")
                    .font(DesignTokens.Typography.labelLarge)
                    .foregroundColor(isCreateMode ? Color.App.textSecondary : Color.App.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                            .fill(isCreateMode ? Color.clear : Color.App.surface)
                    )
            }
            .accessibilityLabel("Sign in mode")
            .accessibilityAddTraits(isCreateMode ? [] : .isSelected)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCreateMode = true
                }
                HapticManager.shared.impact(style: .light)
            } label: {
                Text("Create Account")
                    .font(DesignTokens.Typography.labelLarge)
                    .foregroundColor(isCreateMode ? Color.App.textPrimary : Color.App.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                            .fill(isCreateMode ? Color.App.surface : Color.clear)
                    )
            }
            .accessibilityLabel("Create account mode")
            .accessibilityAddTraits(isCreateMode ? .isSelected : [])
        }
        .padding(DesignTokens.Spacing.xxs)
        .background(Color.App.backgroundSecondary)
        .cornerRadius(DesignTokens.Radius.md)
    }

    // MARK: - Password Strength View
    private var passwordStrengthView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index < passwordStrength.bars ? passwordStrength.color : Color.App.border)
                        .frame(height: 4)
                }
            }

            HStack {
                Image(systemName: passwordStrength.icon)
                    .font(.system(size: 12))
                    .foregroundColor(passwordStrength.color)

                Text(passwordStrength.label)
                    .font(DesignTokens.Typography.labelSmall)
                    .foregroundColor(passwordStrength.color)

                Spacer()

                if passwordStrength != .strong {
                    Text(passwordStrength.hint)
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(Color.App.textTertiary)
                }
            }
        }
        .padding(.top, DesignTokens.Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Password strength: \(passwordStrength.label). \(passwordStrength.hint)")
    }

    // MARK: - Divider Section
    private var dividerSection: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.App.border)

            Text("or")
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(Color.App.textTertiary)

            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.App.border)
        }
    }

    // MARK: - Social Login Section
    private var socialLoginSection: some View {
        GoogleSignInButton(scheme: .dark, style: .wide, state: .normal) {
            signInWithGoogle()
        }
        .frame(height: DesignTokens.TouchTarget.comfortable)
        .cornerRadius(DesignTokens.Radius.md)
    }

    // MARK: - Biometric Section
    private var biometricSection: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Divider()
                .background(Color.App.border)

            Button {
                attemptBiometricAuth()
            } label: {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: biometricIconName)
                        .font(.system(size: DesignTokens.IconSize.lg))
                        .foregroundColor(Color.App.primary)

                    Text("Sign in with \(biometricService.biometricTypeName)")
                        .font(DesignTokens.Typography.bodyLarge)
                        .foregroundColor(Color.App.textPrimary)
                }
                .padding(DesignTokens.Spacing.md)
            }
            .accessibilityLabel("Sign in with \(biometricService.biometricTypeName)")
            .accessibilityHint("Double tap to authenticate using \(biometricService.biometricTypeName)")
        }
    }

    private var biometricIconName: String {
        switch biometricService.biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        default:
            return "lock.fill"
        }
    }

    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.App.overlay.ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.md) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.App.primary))
                    .scaleEffect(1.5)

                Text("Signing in...")
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(Color.App.textPrimary)
            }
            .padding(DesignTokens.Spacing.xxl)
            .background(Color.App.backgroundElevated)
            .cornerRadius(DesignTokens.Radius.lg)
        }
    }

    // MARK: - Actions
    private func handleSubmit() {
        focusedField = nil
        if isCreateMode {
            createAccount()
        } else {
            signIn()
        }
    }

    private func signIn() {
        Task {
            await authViewModel.signIn(email: email, password: password)
        }
    }

    private func createAccount() {
        Task {
            await authViewModel.createAccount(email: email, password: password)
        }
    }

    private func attemptBiometricAuth() {
        guard authViewModel.canUseBiometrics else { return }
        Task {
            await authViewModel.authenticateWithBiometrics()
        }
    }

    private func signInWithGoogle() {
        HapticManager.shared.impact(style: .medium)

        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                authViewModel.errorMessage = error.localizedDescription
                HapticManager.shared.notification(type: .error)
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    authViewModel.errorMessage = error.localizedDescription
                    HapticManager.shared.notification(type: .error)
                } else {
                    HapticManager.shared.notification(type: .success)
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}

// MARK: - Password Strength
enum PasswordStrength: Equatable {
    case weak
    case fair
    case good
    case strong

    var label: String {
        switch self {
        case .weak: return "Weak"
        case .fair: return "Fair"
        case .good: return "Good"
        case .strong: return "Strong"
        }
    }

    var hint: String {
        switch self {
        case .weak: return "Add more characters"
        case .fair: return "Add numbers or symbols"
        case .good: return "Almost there!"
        case .strong: return "Great password!"
        }
    }

    var color: Color {
        switch self {
        case .weak: return Color.App.error
        case .fair: return .orange
        case .good: return .yellow
        case .strong: return Color.App.success
        }
    }

    var icon: String {
        switch self {
        case .weak: return "xmark.circle.fill"
        case .fair: return "exclamationmark.circle.fill"
        case .good: return "checkmark.circle"
        case .strong: return "checkmark.circle.fill"
        }
    }

    var bars: Int {
        switch self {
        case .weak: return 1
        case .fair: return 2
        case .good: return 3
        case .strong: return 4
        }
    }

    static func evaluate(_ password: String) -> PasswordStrength {
        guard !password.isEmpty else { return .weak }

        var score = 0

        // Length checks
        if password.count >= 6 { score += 1 }
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }

        // Character type checks
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumbers = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialChars = password.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil

        if hasUppercase && hasLowercase { score += 1 }
        if hasNumbers { score += 1 }
        if hasSpecialChars { score += 1 }

        switch score {
        case 0...2: return .weak
        case 3: return .fair
        case 4...5: return .good
        default: return .strong
        }
    }
}
