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
    case error(String)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

struct AISessionView: View {
    @StateObject private var viewModel = AISessionViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var pulseScale: CGFloat = 1.0
    @State private var showErrorAlert = false

    var body: some View {
        ZStack {
            // Dark background
            Color.App.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        Task {
                            await endSession()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: DesignTokens.IconSize.lg))
                            .foregroundColor(Color.App.textTertiary)
                    }
                    .padding(DesignTokens.Spacing.lg)
                }

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
        .onChange(of: viewModel.connectionState) { oldValue, newValue in
            if case .error = newValue {
                showErrorAlert = true
                HapticManager.shared.notification(type: .error)
            } else if case .connected = newValue {
                HapticManager.shared.notification(type: .success)
            }
        }
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
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2.5)

                case .error:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: DesignTokens.IconSize.massive))
                        .foregroundColor(Color.App.error)

                case .connected, .disconnected:
                    Image(systemName: viewModel.connectionState.isConnected ? "mic.fill" : "mic")
                        .font(.system(size: DesignTokens.IconSize.massive))
                        .foregroundStyle(
                            viewModel.connectionState.isConnected
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

            case .error:
                statusLabel("CONNECTION FAILED", color: Color.App.error)

            case .connected:
                if viewModel.remoteAudioLevel > 0.1 {
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
    }

    // MARK: - Bottom Controls
    private var bottomControls: some View {
        HStack {
            Spacer()

            Button {
                HapticManager.shared.impact(style: .medium)
                Task {
                    await endSession()
                }
            } label: {
                Text("End Session")
                    .font(DesignTokens.Typography.titleMedium)
                    .foregroundColor(.white)
                    .frame(width: 160, height: DesignTokens.TouchTarget.comfortable)
                    .background(Color.App.error)
                    .cornerRadius(DesignTokens.Radius.full)
            }

            Spacer()
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

    private func startSession() async {
        await viewModel.connect()
    }

    private func endSession() async {
        await viewModel.disconnect()
        dismiss()
    }
}

// MARK: - AI Session ViewModel
@MainActor
final class AISessionViewModel: ObservableObject {
    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var localAudioLevel: CGFloat = 0
    @Published private(set) var remoteAudioLevel: CGFloat = 0

    private let liveKitService = LiveKitService()
    private var audioMonitor: AudioLevelMonitor?

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
            } else {
                connectionState = .error("Failed to connect to voice service")
            }

        } catch {
            connectionState = .error(error.localizedDescription)
        }
    }

    func disconnect() async {
        stopAudioMonitoring()
        await liveKitService.disconnect()
        connectionState = .disconnected
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
