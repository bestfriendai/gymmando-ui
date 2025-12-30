import SwiftUI
import AVFoundation
import LiveKit
import Combine
import os.log

// MARK: - Connection State
enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case error(String)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    var isReconnecting: Bool {
        if case .reconnecting = self { return true }
        return false
    }
}

// MARK: - Session Summary Data
struct SessionSummary {
    let duration: TimeInterval
    let date: Date

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    var motivationalMessage: String {
        switch duration {
        case 0..<60:
            return "Every second counts! Come back for more."
        case 60..<300:
            return "Solid start! Keep building the habit."
        case 300..<600:
            return "Great session! You're making progress."
        case 600..<1200:
            return "Impressive dedication! You're on fire! 🔥"
        default:
            return "Amazing workout! You're a champion! 🏆"
        }
    }
}

struct AISessionView: View {
    @StateObject private var viewModel = AISessionViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var pulseScale: CGFloat = 1.0
    @State private var showErrorAlert = false
    @State private var showEndSessionConfirmation = false
    @State private var showSessionSummary = false
    @State private var sessionSummary: SessionSummary?

    // Connection tips that rotate while connecting
    private let connectionTips = [
        "Preparing your AI coach...",
        "Setting up voice connection...",
        "Almost ready...",
        "Tip: Speak clearly for best results"
    ]
    @State private var currentTipIndex = 0

    var body: some View {
        ZStack {
            // Dark background
            Color.App.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with close button and timer
                topBar

                Spacer()

                // Main visualization area
                mainVisualization

                Spacer()

                // Status text
                statusText
                    .padding(.bottom, DesignTokens.Spacing.lg)

                // Bottom control bar
                bottomControls
                    .padding(.bottom, DesignTokens.Spacing.xxxl)
            }
        }
        .onAppear {
            startPulseAnimation()
            startConnectionTipRotation()
            Task {
                await startSession()
            }
        }
        .onDisappear {
            Task {
                await endSession()
            }
        }
        .alert("Connection Error", isPresented: $showErrorAlert) {
            Button("Retry") {
                Task {
                    await startSession()
                }
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            if case .error(let message) = viewModel.connectionState {
                Text(message)
            } else {
                Text("Failed to connect to the AI assistant.")
            }
        }
        .confirmationDialog(
            "End Session?",
            isPresented: $showEndSessionConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Session", role: .destructive) {
                Task {
                    await endSession()
                }
            }
            Button("Continue", role: .cancel) {}
        } message: {
            Text("Your session has been running for \(viewModel.formattedDuration).")
        }
        .onChange(of: viewModel.connectionState) { oldValue, newValue in
            if case .error = newValue {
                showErrorAlert = true
                HapticManager.shared.notification(type: .error)
            } else if case .connected = newValue {
                HapticManager.shared.notification(type: .success)
            }
        }
        .trackScreen("AISession")
        .sheet(isPresented: $showSessionSummary) {
            if let summary = sessionSummary {
                SessionSummaryView(summary: summary) {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            // Session timer with connection quality
            if viewModel.connectionState.isConnected {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    // Connection quality indicator
                    ConnectionQualityIndicator(quality: viewModel.connectionQuality, size: 14)

                    Divider()
                        .frame(height: 16)
                        .background(Color.App.border)

                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Circle()
                            .fill(Color.App.success)
                            .frame(width: 8, height: 8)

                        Text(viewModel.formattedDuration)
                            .font(DesignTokens.Typography.mono)
                            .foregroundColor(Color.App.textSecondary)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(Color.App.surface)
                .cornerRadius(DesignTokens.Radius.full)
                .accessibilityLabel("Connection \(viewModel.connectionQuality.label). Session duration: \(viewModel.formattedDuration)")
            } else if viewModel.connectionState.isReconnecting {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.App.warning))
                        .scaleEffect(0.8)

                    Text("Reconnecting...")
                        .font(DesignTokens.Typography.labelMedium)
                        .foregroundColor(Color.App.warning)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(Color.App.warning.opacity(0.1))
                .cornerRadius(DesignTokens.Radius.full)
            }

            Spacer()

            // Close button
            Button {
                if viewModel.connectionState.isConnected && viewModel.sessionDuration > 10 {
                    showEndSessionConfirmation = true
                } else {
                    Task {
                        await endSession()
                    }
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: DesignTokens.IconSize.lg))
                    .foregroundColor(Color.App.textTertiary)
            }
            .accessibilityLabel("Close session")
        }
        .padding(DesignTokens.Spacing.lg)
    }

    // MARK: - Main Visualization
    private var mainVisualization: some View {
        ZStack {
            // Waveform behind mic
            SessionWaveformView(
                audioLevel: max(viewModel.localAudioLevel, viewModel.remoteAudioLevel),
                isActive: viewModel.connectionState.isConnected
            )
            .frame(height: 140)
            .padding(.horizontal, DesignTokens.Spacing.xxl)

            // Pulsing rings when active
            if viewModel.connectionState.isConnected {
                pulsingRings
            }

            // Center mic/status indicator
            centerIndicator
        }
        .padding(.bottom, DesignTokens.Spacing.xxxl)
    }

    private var pulsingRings: some View {
        ZStack {
            Circle()
                .stroke(Color.App.success.opacity(0.4), lineWidth: 2)
                .frame(width: 180, height: 180)
                .scaleEffect(pulseScale)
                .opacity(2 - pulseScale)

            Circle()
                .stroke(Color.App.secondary.opacity(0.3), lineWidth: 1)
                .frame(width: 220, height: 220)
                .scaleEffect(pulseScale * 0.9)
                .opacity(2 - pulseScale)
        }
    }

    private var centerIndicator: some View {
        ZStack {
            // Glow circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            viewModel.connectionState.isConnected
                                ? Color.App.primary.opacity(0.5)
                                : Color.App.textPrimary.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)

            // Icon based on state
            Group {
                switch viewModel.connectionState {
                case .connecting:
                    VStack(spacing: DesignTokens.Spacing.md) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(2.5)

                        Text(connectionTips[currentTipIndex])
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(Color.App.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(width: 200)
                            .animation(.easeInOut, value: currentTipIndex)
                    }

                case .reconnecting:
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: DesignTokens.IconSize.massive))
                            .foregroundColor(Color.App.warning)
                            .rotationEffect(.degrees(viewModel.sessionDuration.truncatingRemainder(dividingBy: 1) * 360))

                        Text("Reconnecting...")
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(Color.App.warning)
                    }

                case .error:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: DesignTokens.IconSize.massive))
                        .foregroundColor(Color.App.error)

                case .connected, .disconnected:
                    Image(systemName: viewModel.isMuted ? "mic.slash.fill" : (viewModel.connectionState.isConnected ? "mic.fill" : "mic"))
                        .font(.system(size: DesignTokens.IconSize.massive))
                        .foregroundStyle(
                            viewModel.isMuted
                                ? LinearGradient(colors: [Color.App.error, Color.App.error.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                                : viewModel.connectionState.isConnected
                                    ? LinearGradient(
                                        colors: [.white, Color.App.primary],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    : LinearGradient(
                                        colors: [.white, .gray],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                        )
                        .shadow(
                            color: viewModel.connectionState.isConnected
                                ? Color.App.primary.opacity(0.8)
                                : Color.App.textPrimary.opacity(0.3),
                            radius: 30
                        )
                }
            }
        }
    }

    // MARK: - Status Text
    private var statusText: some View {
        Group {
            switch viewModel.connectionState {
            case .disconnected:
                statusLabel("TAP TO CONNECT", color: Color.App.textTertiary)

            case .connecting:
                statusLabel("CONNECTING...", color: Color.App.textSecondary)

            case .reconnecting:
                statusLabel("RECONNECTING...", color: Color.App.warning)

            case .error:
                statusLabel("CONNECTION FAILED", color: Color.App.error)

            case .connected:
                if viewModel.isMuted {
                    statusLabel("MUTED", color: Color.App.error)
                } else if viewModel.remoteAudioLevel > 0.1 {
                    statusLabel("GYMMANDO SPEAKING", color: Color.App.secondary)
                } else if viewModel.localAudioLevel > 0.1 {
                    statusLabel("YOU", color: Color.App.success)
                } else {
                    statusLabel("LISTENING...", color: Color.App.textTertiary)
                }
            }
        }
    }

    private func statusLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(DesignTokens.Typography.mono)
            .foregroundColor(color)
            .tracking(2)
            .animation(.easeInOut, value: text)
    }

    // MARK: - Bottom Controls
    private var bottomControls: some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            // Mute button
            if viewModel.connectionState.isConnected {
                Button {
                    viewModel.toggleMute()
                    HapticManager.shared.impact(style: .medium)
                } label: {
                    VStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: viewModel.isMuted ? "mic.slash.fill" : "mic.fill")
                            .font(.system(size: DesignTokens.IconSize.lg))
                            .foregroundColor(viewModel.isMuted ? Color.App.error : Color.App.textPrimary)
                            .frame(width: 56, height: 56)
                            .background(viewModel.isMuted ? Color.App.error.opacity(0.2) : Color.App.surface)
                            .cornerRadius(DesignTokens.Radius.full)

                        Text(viewModel.isMuted ? "Unmute" : "Mute")
                            .font(DesignTokens.Typography.labelSmall)
                            .foregroundColor(Color.App.textSecondary)
                    }
                }
                .accessibilityLabel(viewModel.isMuted ? "Unmute microphone" : "Mute microphone")
            }

            // End Session button
            Button {
                if viewModel.connectionState.isConnected && viewModel.sessionDuration > 10 {
                    showEndSessionConfirmation = true
                    HapticManager.shared.impact(style: .medium)
                } else {
                    HapticManager.shared.impact(style: .medium)
                    Task {
                        await endSession()
                    }
                }
            } label: {
                Text("End Session")
                    .font(DesignTokens.Typography.titleMedium)
                    .foregroundColor(.white)
                    .frame(width: 160, height: DesignTokens.TouchTarget.comfortable)
                    .background(Color.App.error)
                    .cornerRadius(DesignTokens.Radius.full)
            }
            .accessibilityLabel("End session")

            // Speaker button
            if viewModel.connectionState.isConnected {
                Button {
                    viewModel.toggleSpeaker()
                    HapticManager.shared.impact(style: .medium)
                } label: {
                    VStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: viewModel.isSpeakerOn ? "speaker.wave.3.fill" : "speaker.fill")
                            .font(.system(size: DesignTokens.IconSize.lg))
                            .foregroundColor(Color.App.textPrimary)
                            .frame(width: 56, height: 56)
                            .background(Color.App.surface)
                            .cornerRadius(DesignTokens.Radius.full)

                        Text(viewModel.isSpeakerOn ? "Speaker" : "Earpiece")
                            .font(DesignTokens.Typography.labelSmall)
                            .foregroundColor(Color.App.textSecondary)
                    }
                }
                .accessibilityLabel(viewModel.isSpeakerOn ? "Switch to earpiece" : "Switch to speaker")
            }
        }
    }

    // MARK: - Actions
    private func startPulseAnimation() {
        withAnimation(
            .easeOut(duration: 1.5)
            .repeatForever(autoreverses: false)
        ) {
            pulseScale = 1.8
        }
    }

    private func startConnectionTipRotation() {
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { timer in
            if case .connecting = viewModel.connectionState {
                withAnimation {
                    currentTipIndex = (currentTipIndex + 1) % connectionTips.count
                }
            } else if viewModel.connectionState.isConnected {
                timer.invalidate()
            }
        }
    }

    private func startSession() async {
        await viewModel.connect()
    }

    private func endSession() async {
        let duration = viewModel.sessionDuration
        await viewModel.disconnect()

        // Only show summary if session was meaningful (> 5 seconds)
        if duration > 5 {
            sessionSummary = SessionSummary(duration: duration, date: Date())
            showSessionSummary = true
        } else {
            dismiss()
        }
    }
}

// MARK: - Session Summary View
struct SessionSummaryView: View {
    let summary: SessionSummary
    let onDismiss: () -> Void

    @State private var animateStats = false
    @State private var showConfetti = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            Color.App.background.ignoresSafeArea()

            // Confetti overlay for longer sessions
            if showConfetti && summary.duration > 300 {
                ConfettiView()
                    .ignoresSafeArea()
            }

            VStack(spacing: DesignTokens.Spacing.xxl) {
                Spacer()

                // Success indicator
                ZStack {
                    Circle()
                        .fill(Color.App.success.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateStats ? 1.1 : 0.8)

                    Circle()
                        .fill(Color.App.success.opacity(0.2))
                        .frame(width: 90, height: 90)
                        .scaleEffect(animateStats ? 1 : 0.9)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color.App.success)
                        .scaleEffect(animateStats ? 1 : 0)
                }

                // Session Complete text
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text("Session Complete!")
                        .font(DesignTokens.Typography.headlineLarge)
                        .foregroundColor(Color.App.textPrimary)

                    Text(summary.motivationalMessage)
                        .font(DesignTokens.Typography.bodyLarge)
                        .foregroundColor(Color.App.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                }
                .opacity(animateStats ? 1 : 0)
                .offset(y: animateStats ? 0 : 20)

                // Stats cards
                HStack(spacing: DesignTokens.Spacing.md) {
                    SummaryStatCard(
                        icon: "clock.fill",
                        value: summary.formattedDuration,
                        label: "Duration",
                        color: .cyan
                    )
                    .opacity(animateStats ? 1 : 0)
                    .offset(y: animateStats ? 0 : 30)

                    SummaryStatCard(
                        icon: "flame.fill",
                        value: "+1",
                        label: "Streak Day",
                        color: .orange
                    )
                    .opacity(animateStats ? 1 : 0)
                    .offset(y: animateStats ? 0 : 30)
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)

                // Achievement unlocked (for first session)
                if summary.duration > 60 {
                    achievementCard
                        .opacity(animateStats ? 1 : 0)
                        .offset(y: animateStats ? 0 : 30)
                }

                Spacer()

                // Done button
                Button {
                    HapticManager.shared.impact(style: .medium)
                    onDismiss()
                } label: {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.bottom, DesignTokens.Spacing.xxxl)
                .opacity(animateStats ? 1 : 0)
            }
        }
        .onAppear {
            HapticManager.shared.notification(type: .success)

            if reduceMotion {
                animateStats = true
                showConfetti = true
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                    animateStats = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showConfetti = true
                }
            }
        }
        .interactiveDismissDisabled()
    }

    private var achievementCard: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: "star.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.yellow)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Progress")
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(Color.App.textSecondary)

                Text("Getting Started")
                    .font(DesignTokens.Typography.titleSmall)
                    .foregroundColor(Color.App.textPrimary)
            }

            Spacer()

            Text("1/3")
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(Color.App.textTertiary)
        }
        .padding(DesignTokens.Spacing.md)
        .background(Color.App.surface)
        .cornerRadius(DesignTokens.Radius.lg)
        .padding(.horizontal, DesignTokens.Spacing.xl)
    }
}

// MARK: - Summary Stat Card
struct SummaryStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }

            Text(value)
                .font(DesignTokens.Typography.headlineSmall)
                .foregroundColor(Color.App.textPrimary)

            Text(label)
                .font(DesignTokens.Typography.labelSmall)
                .foregroundColor(Color.App.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.lg)
        .background(Color.App.surface)
        .cornerRadius(DesignTokens.Radius.lg)
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece, screenHeight: geometry.size.height)
                }
            }
        }
        .onAppear {
            if !reduceMotion {
                generateConfetti()
            }
        }
        .accessibilityHidden(true)
    }

    private func generateConfetti() {
        for _ in 0..<30 {
            confettiPieces.append(ConfettiPiece())
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let x: CGFloat = CGFloat.random(in: 0...1)
    let delay: Double = Double.random(in: 0...0.5)
    let rotation: Double = Double.random(in: 0...360)
    let color: Color = [Color.App.primary, Color.App.secondary, .yellow, .orange, .cyan, .purple].randomElement()!
    let size: CGFloat = CGFloat.random(in: 6...12)
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    let screenHeight: CGFloat

    @State private var offsetY: CGFloat = -50
    @State private var rotation: Double = 0

    var body: some View {
        Rectangle()
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size * 1.5)
            .rotationEffect(.degrees(rotation))
            .position(x: UIScreen.main.bounds.width * piece.x, y: offsetY)
            .onAppear {
                withAnimation(.easeIn(duration: Double.random(in: 2...3)).delay(piece.delay)) {
                    offsetY = screenHeight + 50
                    rotation = piece.rotation + Double.random(in: 180...720)
                }
            }
    }
}

// MARK: - AI Session ViewModel
@MainActor
final class AISessionViewModel: ObservableObject {
    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var localAudioLevel: CGFloat = 0
    @Published private(set) var remoteAudioLevel: CGFloat = 0
    @Published private(set) var sessionDuration: TimeInterval = 0
    @Published private(set) var isMuted = false
    @Published private(set) var isSpeakerOn = true
    @Published private(set) var connectionQuality: ConnectionQuality = .good

    var formattedDuration: String {
        let minutes = Int(sessionDuration) / 60
        let seconds = Int(sessionDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private let liveKitService = LiveKitService()
    private var audioMonitor: AudioLevelMonitor?
    private var durationTimer: Timer?
    private var sessionStartTime: Date?

    init() {
        setupObservers()
    }

    private func setupObservers() {
        // Observe LiveKit connection state
        liveKitService.$connected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                if connected {
                    self?.connectionState = .connected
                    self?.startDurationTimer()
                }
            }
            .store(in: &cancellables)

        // Observe reconnecting state
        liveKitService.$isReconnecting
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isReconnecting in
                if isReconnecting {
                    self?.connectionState = .reconnecting
                }
            }
            .store(in: &cancellables)

        // Observe remote audio level
        liveKitService.$remoteAudioLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.remoteAudioLevel = CGFloat(level)
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()
    private var qualityCheckTimer: Timer?
    private var lastAudioTimestamp: Date = Date()
    private var reconnectCount = 0

    func connect() async {
        connectionState = .connecting

        do {
            guard let tokenURL = AppConfig.API.tokenURL else {
                connectionState = .error("Invalid configuration")
                return
            }

            // Fetch token
            let (data, response) = try await URLSession.shared.data(from: tokenURL)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                connectionState = .error("Server returned an error")
                return
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let token = json["token"] as? String else {
                connectionState = .error("Invalid token response")
                return
            }

            // Connect to LiveKit
            await liveKitService.connect(
                url: AppConfig.API.liveKitURL,
                token: token
            )

            if liveKitService.connected {
                connectionState = .connected
                startAudioMonitoring()
                startDurationTimer()
                startQualityMonitoring()

                // Track session start
                AnalyticsService.shared.track(.sessionStarted)
            } else {
                connectionState = .error("Failed to connect to voice service")
            }

        } catch {
            connectionState = .error(error.localizedDescription)
        }
    }

    func disconnect() async {
        stopDurationTimer()
        stopAudioMonitoring()
        stopQualityMonitoring()
        await liveKitService.disconnect()
        connectionState = .disconnected

        // Track session end with duration
        AnalyticsService.shared.track(.sessionEnded, parameters: [
            "duration_seconds": Int(sessionDuration)
        ])
        AnalyticsService.shared.trackSessionDuration(Int(sessionDuration))
    }

    func toggleMute() {
        isMuted.toggle()
        // TODO: Actually mute the microphone via LiveKit
        // liveKitService.setMicrophoneEnabled(!isMuted)
    }

    func toggleSpeaker() {
        isSpeakerOn.toggle()
        do {
            let audioSession = AVAudioSession.sharedInstance()
            if isSpeakerOn {
                try audioSession.overrideOutputAudioPort(.speaker)
            } else {
                try audioSession.overrideOutputAudioPort(.none)
            }
        } catch {
            // Handle error silently
        }
    }

    private func startDurationTimer() {
        sessionStartTime = Date()
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.sessionStartTime else { return }
            Task { @MainActor in
                self.sessionDuration = Date().timeIntervalSince(startTime)
            }
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }

    private func startAudioMonitoring() {
        audioMonitor = AudioLevelMonitor { [weak self] level in
            self?.localAudioLevel = level
        }
        audioMonitor?.start()
    }

    private func stopAudioMonitoring() {
        audioMonitor?.stop()
        audioMonitor = nil
        localAudioLevel = 0
    }

    private func startQualityMonitoring() {
        qualityCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateConnectionQuality()
            }
        }
    }

    private func stopQualityMonitoring() {
        qualityCheckTimer?.invalidate()
        qualityCheckTimer = nil
    }

    private func updateConnectionQuality() {
        // Simulate quality based on various factors
        // In a real app, this would use actual network metrics from LiveKit

        // Check if we're receiving audio
        let hasRecentAudio = remoteAudioLevel > 0.05

        // Check reconnection state
        if connectionState.isReconnecting {
            connectionQuality = .poor
            reconnectCount += 1
            return
        }

        // Reset reconnect count if stable
        if connectionState.isConnected && !connectionState.isReconnecting {
            if reconnectCount > 0 {
                reconnectCount = max(0, reconnectCount - 1)
            }
        }

        // Determine quality based on factors
        if reconnectCount >= 3 {
            connectionQuality = .poor
        } else if reconnectCount >= 1 {
            connectionQuality = .fair
        } else if hasRecentAudio || localAudioLevel > 0.1 {
            connectionQuality = .excellent
        } else {
            connectionQuality = .good
        }
    }
}

// MARK: - Session Waveform View
struct SessionWaveformView: View {
    let audioLevel: CGFloat
    let isActive: Bool

    private let barCount = 12
    private let barSpacing: CGFloat = 8
    private let barCornerRadius: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            let barWidth = (geo.size.width - CGFloat(barCount - 1) * barSpacing) / CGFloat(barCount)
            let halfHeight = geo.size.height / 2

            HStack(alignment: .center, spacing: barSpacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    SessionBarView(
                        index: index,
                        barCount: barCount,
                        audioLevel: audioLevel,
                        isActive: isActive,
                        halfHeight: halfHeight,
                        barWidth: barWidth,
                        barCornerRadius: barCornerRadius
                    )
                }
            }
            .frame(height: geo.size.height)
        }
    }
}

struct SessionBarView: View {
    let index: Int
    let barCount: Int
    let audioLevel: CGFloat
    let isActive: Bool
    let halfHeight: CGFloat
    let barWidth: CGFloat
    let barCornerRadius: CGFloat

    @State private var trailLevel: CGFloat = 0
    @State private var currentHeight: CGFloat = 3

    private var envelope: CGFloat {
        let position = CGFloat(index) / CGFloat(barCount - 1)
        return sin(.pi * position)
    }

    private var targetHeight: CGFloat {
        let baseHeight: CGFloat = 3
        let dynamicHeight = isActive ? audioLevel * halfHeight * 0.9 * envelope : 0
        let randomFactor = CGFloat(((index * 7 + 3) % 10)) / 10.0
        return max(baseHeight, baseHeight + dynamicHeight + (isActive ? dynamicHeight * randomFactor * 0.3 : 0))
    }

    var body: some View {
        let totalHeight = currentHeight * 2
        let trailTotalHeight = max(6, (3 + trailLevel * halfHeight * 0.9 * envelope) * 2)

        let baseOpacity: CGFloat = 0.2
        let audioOpacity = isActive ? audioLevel * 0.8 : 0
        let finalOpacity = min(1.0, baseOpacity + audioOpacity * envelope)
        let trailOpacity = min(0.4, 0.1 + trailLevel * 0.3 * envelope)

        ZStack {
            // Trail
            RoundedRectangle(cornerRadius: barCornerRadius)
                .fill(Color.App.success.opacity(0.6))
                .frame(width: barWidth, height: trailTotalHeight)
                .opacity(trailOpacity)
                .blur(radius: 3)

            // Main bar
            RoundedRectangle(cornerRadius: barCornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Color.App.success, Color.App.secondary, Color.App.success],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: barWidth, height: totalHeight)
                .opacity(finalOpacity)
                .shadow(color: Color.App.secondary.opacity(0.8 * finalOpacity), radius: 6)
        }
        .animation(.easeInOut(duration: 0.12), value: currentHeight)
        .animation(.easeOut(duration: 0.25), value: trailLevel)
        .onChange(of: audioLevel) { _, newValue in
            currentHeight = targetHeight

            if newValue > trailLevel {
                trailLevel = newValue
            } else {
                trailLevel = trailLevel * 0.9
            }
        }
    }
}

// MARK: - Audio Level Monitor
final class AudioLevelMonitor {
    private var audioEngine: AVAudioEngine?
    private let onLevelUpdate: (CGFloat) -> Void
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Gymmando", category: "AudioMonitor")

    init(onLevelUpdate: @escaping (CGFloat) -> Void) {
        self.onLevelUpdate = onLevelUpdate
    }

    func start() {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frames = buffer.frameLength

            var sum: Float = 0
            for i in 0..<Int(frames) {
                sum += abs(channelData[i])
            }
            let avg = sum / Float(frames)

            DispatchQueue.main.async {
                self?.onLevelUpdate(CGFloat(min(avg * 10, 1.0)))
            }
        }

        do {
            try engine.start()
            self.audioEngine = engine
        } catch {
            logger.error("Audio engine error: \(error.localizedDescription)")
        }
    }

    func stop() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
    }

    deinit {
        stop()
    }
}

#Preview {
    AISessionView()
}
