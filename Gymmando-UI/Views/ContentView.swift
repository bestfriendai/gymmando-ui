import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var showAISession = false
    @State private var showSettings = false
    @State private var showMicrophonePermissionPrompt = false
    @State private var currentTip = 0

    // Motivational tips that rotate
    private let tips = [
        "💪 Consistency beats intensity. Show up every day!",
        "🎯 Set small goals and celebrate small wins.",
        "🔥 Your only competition is who you were yesterday.",
        "⚡ Energy flows where focus goes.",
        "🏆 Progress, not perfection."
    ]

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<22:
            return "Good evening"
        default:
            return "Hey there"
        }
    }

    private var motivationalSubtitle: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Ready for a morning workout?"
        case 12..<17:
            return "Perfect time to get moving!"
        case 17..<22:
            return "Let's finish the day strong!"
        default:
            return "Never too late to train!"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background
                Color.App.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Network status banner
                    if !networkMonitor.status.isConnected {
                        NetworkStatusBanner()
                    }

                    ScrollView {
                        VStack(spacing: DesignTokens.Spacing.lg) {
                            // Header with personalized greeting
                            headerSection
                                .padding(.top, DesignTokens.Spacing.lg)

                            // Motivational tip card
                            tipCard

                            // Main CTA - Start AI Session
                            mainContentSection

                            // Quick Actions
                            quickActionsSection

                            // Stats Section
                            statsSection
                        }
                        .screenPadding()
                        .padding(.bottom, DesignTokens.Spacing.xl)
                    }
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
            .sheet(isPresented: $showMicrophonePermissionPrompt) {
                MicrophonePermissionView {
                    showMicrophonePermissionPrompt = false
                    showAISession = true
                }
            }
            .fullScreenCover(isPresented: $showAISession) {
                AISessionView()
            }
            .onAppear {
                // Rotate tips periodically
                startTipRotation()
            }
            .trackScreen("Home")
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            if let user = authViewModel.currentUser {
                Text("\(greeting), \(user.firstName)!")
                    .font(DesignTokens.Typography.headlineMedium)
                    .foregroundColor(Color.App.textPrimary)
                    .accessibilityAddTraits(.isHeader)
            } else {
                Text("\(greeting)!")
                    .font(DesignTokens.Typography.headlineMedium)
                    .foregroundColor(Color.App.textPrimary)
                    .accessibilityAddTraits(.isHeader)
            }

            Text(motivationalSubtitle)
                .font(DesignTokens.Typography.bodyLarge)
                .foregroundColor(Color.App.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Tip Card
    private var tipCard: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Text(tips[currentTip])
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(Color.App.textPrimary)
                .lineLimit(2)
                .animation(.easeInOut, value: currentTip)

            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            LinearGradient(
                colors: [Color.App.primary.opacity(0.15), Color.App.secondary.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(DesignTokens.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .stroke(Color.App.primary.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            withAnimation {
                currentTip = (currentTip + 1) % tips.count
            }
            HapticManager.shared.impact(style: .light)
        }
        .accessibilityLabel("Motivational tip: \(tips[currentTip])")
        .accessibilityHint("Tap to see another tip")
    }

    // MARK: - Main Content Section
    private var mainContentSection: some View {
        Button {
            handleStartSession()
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
            .frame(height: 180)
            .background(Color.App.surface)
            .cornerRadius(DesignTokens.Radius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .stroke(Color.App.border, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!networkMonitor.status.isConnected)
        .opacity(networkMonitor.status.isConnected ? 1.0 : 0.6)
        .accessibilityLabel("Start AI Session")
        .accessibilityHint(networkMonitor.status.isConnected
            ? "Double tap to talk to your AI fitness coach"
            : "No internet connection. Connect to start a session.")
        .accessibilityIdentifier(AccessibilityID.startSessionButton)
    }

    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Quick Actions")
                .font(DesignTokens.Typography.titleSmall)
                .foregroundColor(Color.App.textTertiary)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: DesignTokens.Spacing.md) {
                QuickActionCard(
                    icon: "lightbulb.fill",
                    title: "Workout Tips",
                    color: .yellow
                ) {
                    // TODO: Navigate to tips
                    HapticManager.shared.impact(style: .light)
                }

                QuickActionCard(
                    icon: "clock.arrow.circlepath",
                    title: "History",
                    color: .purple
                ) {
                    // TODO: Navigate to history
                    HapticManager.shared.impact(style: .light)
                }

                QuickActionCard(
                    icon: "target",
                    title: "Goals",
                    color: .green
                ) {
                    // TODO: Navigate to goals
                    HapticManager.shared.impact(style: .light)
                }
            }
        }
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Your Progress")
                    .font(DesignTokens.Typography.titleSmall)
                    .foregroundColor(Color.App.textTertiary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button("View All") {
                    // TODO: Navigate to detailed stats
                    HapticManager.shared.impact(style: .light)
                }
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(Color.App.primary)
            }

            HStack(spacing: DesignTokens.Spacing.md) {
                StatCard(title: "Sessions", value: "0", icon: "waveform", trend: nil)
                StatCard(title: "Minutes", value: "0", icon: "clock.fill", trend: nil)
                StatCard(title: "Streak", value: "0", icon: "flame.fill", trend: nil)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(AccessibilityID.statsSection)
        }
    }

    // MARK: - Actions
    private func handleStartSession() {
        HapticManager.shared.impact(style: .medium)

        // Check microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    showAISession = true
                } else {
                    showMicrophonePermissionPrompt = true
                }
            }
        }
    }

    private func startTipRotation() {
        // Rotate tips every 8 seconds
        Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
            withAnimation {
                currentTip = (currentTip + 1) % tips.count
            }
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: DesignTokens.IconSize.lg))
                    .foregroundColor(color)

                Text(title)
                    .font(DesignTokens.Typography.labelSmall)
                    .foregroundColor(Color.App.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(Color.App.backgroundSecondary)
            .cornerRadius(DesignTokens.Radius.md)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(title)
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let trend: String? // e.g., "+2" or nil

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: DesignTokens.IconSize.md))
                .foregroundColor(Color.App.primary)
                .accessibilityHidden(true)

            HStack(spacing: 2) {
                Text(value)
                    .font(DesignTokens.Typography.headlineSmall)
                    .foregroundColor(Color.App.textPrimary)

                if let trend = trend {
                    Text(trend)
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(Color.App.success)
                }
            }

            Text(title)
                .font(DesignTokens.Typography.labelSmall)
                .foregroundColor(Color.App.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.md)
        .background(Color.App.backgroundSecondary)
        .cornerRadius(DesignTokens.Radius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)\(trend != nil ? ", \(trend!) from last week" : "")")
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

// MARK: - Microphone Permission View
struct MicrophonePermissionView: View {
    let onContinue: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.App.background.ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.xxl) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.App.primary.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color.App.primary)
                }

                // Text
                VStack(spacing: DesignTokens.Spacing.md) {
                    Text("Microphone Access Required")
                        .font(DesignTokens.Typography.headlineSmall)
                        .foregroundColor(Color.App.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Gymmando needs access to your microphone to hear your voice and provide real-time coaching during your workout sessions.")
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(Color.App.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                }

                // Benefits
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    PermissionBenefit(icon: "waveform", text: "Voice-activated workout guidance")
                    PermissionBenefit(icon: "person.wave.2", text: "Hands-free interaction")
                    PermissionBenefit(icon: "lock.shield", text: "Audio is processed securely")
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)

                Spacer()

                // Buttons
                VStack(spacing: DesignTokens.Spacing.md) {
                    Button {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                        dismiss()
                    } label: {
                        Text("Open Settings")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        dismiss()
                    } label: {
                        Text("Not Now")
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(Color.App.textSecondary)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.bottom, DesignTokens.Spacing.xxxl)
            }
        }
    }
}

struct PermissionBenefit: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: DesignTokens.IconSize.sm))
                .foregroundColor(Color.App.success)
                .frame(width: 24)

            Text(text)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(Color.App.textPrimary)
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showLogoutConfirmation = false
    @State private var showProfile = false
    @State private var showNotifications = false
    @State private var showAppearance = false
    @State private var showPrivacy = false
    @State private var showHelpCenter = false
    @State private var showDeleteAccount = false

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
                        SettingsRow(icon: "bell.fill", title: "Notifications", color: .red) {
                            showNotifications = true
                        }
                        SettingsRow(icon: "moon.fill", title: "Appearance", color: .purple) {
                            showAppearance = true
                        }
                        SettingsRow(icon: "hand.raised.fill", title: "Privacy", color: .blue) {
                            showPrivacy = true
                        }
                    }
                    .listRowBackground(Color.App.surface)

                    // Support Section
                    Section("Support") {
                        SettingsRow(icon: "questionmark.circle.fill", title: "Help Center", color: .green) {
                            showHelpCenter = true
                        }
                        SettingsRow(icon: "envelope.fill", title: "Contact Us", color: .orange) {
                            // Open email
                            if let url = URL(string: "mailto:support@gymmando.com") {
                                UIApplication.shared.open(url)
                            }
                        }
                        SettingsRow(icon: "star.fill", title: "Rate App", color: .yellow) {
                            // Open App Store rating
                            HapticManager.shared.notification(type: .success)
                        }
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

                        Button {
                            showDeleteAccount = true
                            HapticManager.shared.impact(style: .heavy)
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(Color.App.error)
                                Text("Delete Account")
                                    .foregroundColor(Color.App.error)
                            }
                        }
                        .listRowBackground(Color.App.surface)
                    }

                    // App Info
                    Section {
                        HStack {
                            Text("Version")
                                .foregroundColor(Color.App.textSecondary)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(Color.App.textTertiary)
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
            .confirmationDialog(
                "Delete Account",
                isPresented: $showDeleteAccount,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) {
                    // TODO: Implement account deletion
                    authViewModel.signOutCompletely()
                    HapticManager.shared.notification(type: .success)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsSettingsView()
            }
            .sheet(isPresented: $showAppearance) {
                AppearanceSettingsView()
            }
            .sheet(isPresented: $showPrivacy) {
                PrivacySettingsView()
            }
            .sheet(isPresented: $showHelpCenter) {
                HelpCenterView()
            }
            .trackScreen("Settings")
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

// MARK: - Settings Sub-Views
struct NotificationsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var workoutReminders = true
    @State private var progressUpdates = true
    @State private var tips = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.App.background.ignoresSafeArea()

                List {
                    Section("Reminders") {
                        Toggle("Workout Reminders", isOn: $workoutReminders)
                            .tint(Color.App.primary)
                        Toggle("Progress Updates", isOn: $progressUpdates)
                            .tint(Color.App.primary)
                    }
                    .listRowBackground(Color.App.surface)

                    Section("Updates") {
                        Toggle("Daily Tips", isOn: $tips)
                            .tint(Color.App.primary)
                    }
                    .listRowBackground(Color.App.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.App.primary)
                }
            }
        }
    }
}

struct AppearanceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTheme = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.App.background.ignoresSafeArea()

                List {
                    Section("Theme") {
                        Picker("Appearance", selection: $selectedTheme) {
                            Text("System").tag(0)
                            Text("Light").tag(1)
                            Text("Dark").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.App.surface)
                    }

                    Section(footer: Text("Dark mode is currently always enabled for the best experience.")) {
                        EmptyView()
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.App.primary)
                }
            }
        }
    }
}

struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var analyticsEnabled = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.App.background.ignoresSafeArea()

                List {
                    Section(footer: Text("Help us improve Gymmando by sharing anonymous usage data.")) {
                        Toggle("Share Analytics", isOn: $analyticsEnabled)
                            .tint(Color.App.primary)
                    }
                    .listRowBackground(Color.App.surface)

                    Section("Legal") {
                        Link(destination: URL(string: "https://gymmando.com/privacy")!) {
                            HStack {
                                Text("Privacy Policy")
                                    .foregroundColor(Color.App.textPrimary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.App.textTertiary)
                            }
                        }

                        Link(destination: URL(string: "https://gymmando.com/terms")!) {
                            HStack {
                                Text("Terms of Service")
                                    .foregroundColor(Color.App.textPrimary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.App.textTertiary)
                            }
                        }
                    }
                    .listRowBackground(Color.App.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.App.primary)
                }
            }
        }
    }
}

struct HelpCenterView: View {
    @Environment(\.dismiss) private var dismiss

    private let faqs = [
        ("How do I start a workout?", "Tap the 'Start AI Session' button on the home screen to begin talking with your AI coach."),
        ("Is my voice data stored?", "Voice data is processed in real-time and not permanently stored on our servers."),
        ("Can I use the app offline?", "An internet connection is required to communicate with the AI coach."),
        ("How do I cancel my subscription?", "You can manage your subscription in the App Store settings.")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.App.background.ignoresSafeArea()

                List {
                    Section("Frequently Asked Questions") {
                        ForEach(faqs, id: \.0) { faq in
                            DisclosureGroup {
                                Text(faq.1)
                                    .font(DesignTokens.Typography.bodyMedium)
                                    .foregroundColor(Color.App.textSecondary)
                                    .padding(.vertical, DesignTokens.Spacing.sm)
                            } label: {
                                Text(faq.0)
                                    .font(DesignTokens.Typography.bodyLarge)
                                    .foregroundColor(Color.App.textPrimary)
                            }
                        }
                    }
                    .listRowBackground(Color.App.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Help Center")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.App.primary)
                }
            }
        }
    }
}

// MARK: - AVFoundation Import
import AVFoundation

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
