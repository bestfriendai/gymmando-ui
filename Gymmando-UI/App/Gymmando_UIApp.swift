//
//  Gymmando_UIApp.swift
//  Gymmando-UI
//
//  Created by Abdu Radi on 11/25/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

@main
struct Gymmando_UIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

// MARK: - Root View (Handles Auth State & Onboarding)
struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else {
                switch authViewModel.authState {
                case .loading:
                    SplashView()
                case .unauthenticated:
                    LoginView()
                case .authenticated:
                    ContentView()
                }
            }
        }
        .animation(.easeInOut(duration: AppConfig.Animation.standard), value: authViewModel.authState)
        .animation(.easeInOut(duration: AppConfig.Animation.standard), value: hasCompletedOnboarding)
    }
}

// MARK: - Splash View
struct SplashView: View {
    var body: some View {
        ZStack {
            Color.App.background.ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.lg) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .cornerRadius(DesignTokens.Radius.xl)

                Text("Gymmando")
                    .font(DesignTokens.Typography.headlineLarge)
                    .foregroundColor(Color.App.textPrimary)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.App.primary))
                    .scaleEffect(1.2)
            }
        }
    }
}
