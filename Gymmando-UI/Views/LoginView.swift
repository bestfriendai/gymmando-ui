import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showForgotPassword = false
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password
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

            Text("Gymmando")
                .font(DesignTokens.Typography.displaySmall)
                .foregroundColor(Color.App.textPrimary)

            Text("Your AI Fitness Coach")
                .font(DesignTokens.Typography.bodyLarge)
                .foregroundColor(Color.App.textSecondary)
        }
    }

    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Email Field
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Email")
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(Color.App.textSecondary)

                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(Color.App.textTertiary)
                        .frame(width: DesignTokens.IconSize.md)

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
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit {
                        signIn()
                    }

                    Button {
                        showPassword.toggle()
                        HapticManager.shared.impact(style: .light)
                    } label: {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(Color.App.textTertiary)
                    }
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
            }

            // Forgot Password
            HStack {
                Spacer()
                Button("Forgot Password?") {
                    showForgotPassword = true
                    HapticManager.shared.impact(style: .light)
                }
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(Color.App.primary)
            }

            // Error Message
            if let errorMessage = authViewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color.App.error)
                    Text(errorMessage)
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(Color.App.error)
                }
                .padding(DesignTokens.Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(Color.App.error.opacity(0.1))
                .cornerRadius(DesignTokens.Radius.sm)
            }

            // Sign In Button
            Button(action: signIn) {
                Text("Sign In")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(email.isEmpty || password.isEmpty)

            // Create Account Button
            Button(action: createAccount) {
                Text("Create Account")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(email.isEmpty || password.isEmpty)
        }
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
                    Image(systemName: "faceid")
                        .font(.system(size: DesignTokens.IconSize.lg))
                        .foregroundColor(Color.App.primary)

                    Text("Sign in with Face ID")
                        .font(DesignTokens.Typography.bodyLarge)
                        .foregroundColor(Color.App.textPrimary)
                }
                .padding(DesignTokens.Spacing.md)
            }
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
    private func signIn() {
        focusedField = nil
        Task {
            await authViewModel.signIn(email: email, password: password)
        }
    }

    private func createAccount() {
        focusedField = nil
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
