import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showAISession = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background
                Color.App.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.top, DesignTokens.Spacing.xl)
                        .padding(.bottom, DesignTokens.Spacing.xxxl)

                    // Main content
                    mainContentSection

                    Spacer()

                    // Quick Stats (placeholder for future)
                    statsSection

                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                        HapticManager.shared.impact(style: .light)
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: DesignTokens.IconSize.md))
                            .foregroundColor(Color.App.textSecondary)
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityHint("Double tap to open settings")
                    .accessibilityIdentifier(AccessibilityID.settingsButton)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(authViewModel)
            }
            .fullScreenCover(isPresented: $showAISession) {
                AISessionView()
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Text("Gymmando")
                .font(DesignTokens.Typography.headlineMedium)
                .foregroundColor(Color.App.textPrimary)
                .accessibilityAddTraits(.isHeader)

            if let user = authViewModel.currentUser {
                Text("Ready, \(user.firstName)?")
                    .font(DesignTokens.Typography.bodyLarge)
                    .foregroundColor(Color.App.textSecondary)
            } else {
                Text("Ready to train?")
                    .font(DesignTokens.Typography.bodyLarge)
                    .foregroundColor(Color.App.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Main Content Section
    private var mainContentSection: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Start AI Session Card
            Button {
                showAISession = true
                HapticManager.shared.impact(style: .medium)
            } label: {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Animated waveform
                    ZStack {
                        AnimatedWaveformView()
                            .frame(height: 60)

                        Image(systemName: "mic.fill")
                            .font(.system(size: DesignTokens.IconSize.xl))
                            .foregroundColor(Color.App.primary)
                    }
                    .frame(height: 60)

                    Text("Start AI Session")
                        .font(DesignTokens.Typography.titleMedium)
                        .foregroundColor(Color.App.textPrimary)

                    Text("Talk to your AI fitness coach")
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(Color.App.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color.App.surface)
                .cornerRadius(DesignTokens.Radius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .stroke(Color.App.border, lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Start AI Session")
            .accessibilityHint("Double tap to talk to your AI fitness coach")
            .accessibilityIdentifier(AccessibilityID.startSessionButton)
        }
        .screenPadding()
    }

    // MARK: - Stats Section (Placeholder)
    private var statsSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("Your Progress")
                .font(DesignTokens.Typography.titleSmall)
                .foregroundColor(Color.App.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: DesignTokens.Spacing.md) {
                StatCard(title: "Sessions", value: "0", icon: "waveform")
                StatCard(title: "Minutes", value: "0", icon: "clock.fill")
                StatCard(title: "Streak", value: "0", icon: "flame.fill")
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(AccessibilityID.statsSection)
        }
        .screenPadding()
        .padding(.bottom, DesignTokens.Spacing.xl)
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: DesignTokens.IconSize.md))
                .foregroundColor(Color.App.primary)
                .accessibilityHidden(true)

            Text(value)
                .font(DesignTokens.Typography.headlineSmall)
                .foregroundColor(Color.App.textPrimary)

            Text(title)
                .font(DesignTokens.Typography.labelSmall)
                .foregroundColor(Color.App.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.md)
        .background(Color.App.backgroundSecondary)
        .cornerRadius(DesignTokens.Radius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Animated Waveform (Fixed - No Memory Leak)
struct AnimatedWaveformView: View {
    @State private var animationPhase: CGFloat = 0

    private let barCount = 8
    private let animationDuration: Double = 1.2

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                WaveformBar(
                    index: index,
                    barCount: barCount,
                    phase: animationPhase
                )
            }
        }
        .onAppear {
            // Use continuous animation instead of Timer
            withAnimation(
                .easeInOut(duration: animationDuration)
                .repeatForever(autoreverses: true)
            ) {
                animationPhase = 1.0
            }
        }
    }
}

struct WaveformBar: View {
    let index: Int
    let barCount: Int
    let phase: CGFloat

    private var height: CGFloat {
        let baseHeight: CGFloat = 20
        let maxHeight: CGFloat = 40
        let offset = CGFloat(index) / CGFloat(barCount) * .pi * 2
        let wave = sin(phase * .pi * 2 + offset)
        return baseHeight + (maxHeight - baseHeight) * ((wave + 1) / 2)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [Color.App.secondary, Color.App.primary],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 4, height: height)
            .animation(.easeInOut(duration: 0.3), value: phase)
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showLogoutConfirmation = false
    @State private var showProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.App.background.ignoresSafeArea()

                List {
                    // User Info Section
                    Section {
                        if let user = authViewModel.currentUser {
                            Button {
                                showProfile = true
                                HapticManager.shared.impact(style: .light)
                            } label: {
                                HStack(spacing: DesignTokens.Spacing.md) {
                                    Circle()
                                        .fill(Color.App.primary.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Text(String(user.firstName.prefix(1)).uppercased())
                                                .font(DesignTokens.Typography.titleLarge)
                                                .foregroundColor(Color.App.primary)
                                        )

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(user.displayName ?? "User")
                                            .font(DesignTokens.Typography.titleMedium)
                                            .foregroundColor(Color.App.textPrimary)

                                        Text(user.email ?? "")
                                            .font(DesignTokens.Typography.bodySmall)
                                            .foregroundColor(Color.App.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color.App.textTertiary)
                                }
                            }
                            .listRowBackground(Color.App.surface)
                            .accessibilityLabel("View profile for \(user.displayName ?? "User")")
                            .accessibilityIdentifier(AccessibilityID.userProfile)
                        }
                    }

                    // App Section
                    Section("App") {
                        SettingsRow(icon: "bell.fill", title: "Notifications", color: .red)
                        SettingsRow(icon: "moon.fill", title: "Appearance", color: .purple)
                        SettingsRow(icon: "hand.raised.fill", title: "Privacy", color: .blue)
                    }
                    .listRowBackground(Color.App.surface)

                    // Support Section
                    Section("Support") {
                        SettingsRow(icon: "questionmark.circle.fill", title: "Help Center", color: .green)
                        SettingsRow(icon: "envelope.fill", title: "Contact Us", color: .orange)
                        SettingsRow(icon: "star.fill", title: "Rate App", color: .yellow)
                    }
                    .listRowBackground(Color.App.surface)

                    // Account Section
                    Section {
                        Button {
                            showLogoutConfirmation = true
                            HapticManager.shared.impact(style: .medium)
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(Color.App.error)
                                Text("Sign Out")
                                    .foregroundColor(Color.App.error)
                            }
                        }
                        .listRowBackground(Color.App.surface)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.App.primary)
                }
            }
            .confirmationDialog(
                "Sign Out",
                isPresented: $showLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                    HapticManager.shared.notification(type: .success)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
            HapticManager.shared.impact(style: .light)
        } label: {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: DesignTokens.IconSize.sm))
                    .foregroundColor(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.15))
                    .cornerRadius(6)

                Text(title)
                    .font(DesignTokens.Typography.bodyLarge)
                    .foregroundColor(Color.App.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.App.textTertiary)
            }
        }
        .accessibilityLabel(title)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
