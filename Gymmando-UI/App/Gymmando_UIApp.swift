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
    @State private var isPulsing = false
    @State private var showLogo = false
    @State private var showTitle = false
    @State private var showLoader = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            Color.App.background.ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.lg) {
                ZStack {
                    // Pulse rings (behind logo)
                    if !reduceMotion {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .stroke(Color.App.primary.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                                .frame(width: 120 + CGFloat(index) * 40, height: 120 + CGFloat(index) * 40)
                                .scaleEffect(isPulsing ? 1.1 : 0.9)
                                .opacity(isPulsing ? 0 : 1)
                                .animation(
                                    .easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.3),
                                    value: isPulsing
                                )
                        }
                    }

                    // Logo
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .cornerRadius(DesignTokens.Radius.xl)
                        .shadow(color: Color.App.primary.opacity(0.4), radius: isPulsing ? 20 : 10)
                        .scaleEffect(showLogo ? 1 : 0.8)
                        .opacity(showLogo ? 1 : 0)
                }

                // Title
                Text("Gymmando")
                    .font(DesignTokens.Typography.headlineLarge)
                    .foregroundColor(Color.App.textPrimary)
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 10)

                // Animated loading indicator
                if showLoader {
                    LoadingDotsView()
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        if reduceMotion {
            showLogo = true
            showTitle = true
            showLoader = true
            return
        }

        withAnimation(.easeOut(duration: 0.5)) {
            showLogo = true
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            showTitle = true
        }

        withAnimation(.easeOut(duration: 0.3).delay(0.6)) {
            showLoader = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isPulsing = true
        }
    }
}

// MARK: - Loading Dots View
struct LoadingDotsView: View {
    @State private var animatingDots: [Bool] = [false, false, false]
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.App.primary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animatingDots[index] ? 1.2 : 0.8)
                    .opacity(animatingDots[index] ? 1 : 0.5)
            }
        }
        .onAppear {
            if !reduceMotion {
                startDotAnimation()
            }
        }
        .accessibilityLabel("Loading")
    }

    private func startDotAnimation() {
        for index in 0..<3 {
            withAnimation(
                .easeInOut(duration: 0.4)
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.15)
            ) {
                animatingDots[index] = true
            }
        }
    }
}
