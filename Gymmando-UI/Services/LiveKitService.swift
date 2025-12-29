import Foundation
import LiveKit
import AVFoundation
import Combine
import os.log

/// LiveKit service for real-time voice communication
@MainActor
final class LiveKitService: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var connected = false
    @Published private(set) var remoteAudioLevel: Float = 0
    @Published private(set) var isReconnecting = false

    // MARK: - Private Properties
    private var room: Room?
    private var audioLevelTimer: Timer?
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Gymmando", category: "LiveKit")

    // Reconnection state
    private var lastConnectionURL: String?
    private var lastConnectionToken: String?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 3
    private var reconnectTask: Task<Void, Never>?

    // Network monitoring
    private var networkCancellable: AnyCancellable?
    private var wasConnectedBeforeNetworkLoss = false

    // MARK: - Initialization
    init() {
        setupNetworkMonitoring()
    }

    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        networkCancellable = NetworkMonitor.shared.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                self.handleNetworkStatusChange(status)
            }
    }

    private func handleNetworkStatusChange(_ status: NetworkStatus) {
        switch status {
        case .disconnected:
            if connected {
                wasConnectedBeforeNetworkLoss = true
                logger.warning("Network lost while connected")
            }
        case .connected:
            if wasConnectedBeforeNetworkLoss && !connected {
                logger.info("Network restored, attempting reconnection")
                wasConnectedBeforeNetworkLoss = false
                Task {
                    await attemptReconnect()
                }
            }
        case .unknown:
            break
        }
    }

    // MARK: - Connection
    func connect(url: String, token: String) async {
        // Cancel any pending reconnection
        reconnectTask?.cancel()
        reconnectTask = nil
        reconnectAttempts = 0

        // Disconnect any existing connection first
        if room != nil {
            await disconnect()
        }

        // Store connection info for reconnection
        lastConnectionURL = url
        lastConnectionToken = token

        await performConnect(url: url, token: token)
    }

    private func performConnect(url: String, token: String) async {
        do {
            // Configure audio session
            try await configureAudioSession()

            // Create and connect room
            let newRoom = Room()
            self.room = newRoom

            try await newRoom.connect(url: url, token: token)

            // Enable microphone
            try await newRoom.localParticipant.setMicrophone(enabled: true)

            connected = true
            isReconnecting = false
            reconnectAttempts = 0
            startRemoteAudioMonitoring()

            logger.info("Successfully connected to LiveKit room")

        } catch {
            logger.error("Failed to connect: \(error.localizedDescription)")
            connected = false
            room = nil
        }
    }

    func disconnect() async {
        // Cancel any pending reconnection
        reconnectTask?.cancel()
        reconnectTask = nil
        isReconnecting = false
        wasConnectedBeforeNetworkLoss = false

        stopRemoteAudioMonitoring()

        guard let room = self.room else { return }

        try? await room.localParticipant.setMicrophone(enabled: false)
        await room.disconnect()

        self.connected = false
        self.room = nil
        self.lastConnectionURL = nil
        self.lastConnectionToken = nil

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        logger.info("Disconnected from LiveKit room")
    }

    // MARK: - Reconnection
    func attemptReconnect() async {
        guard let url = lastConnectionURL,
              let token = lastConnectionToken,
              !connected,
              reconnectAttempts < maxReconnectAttempts else {
            isReconnecting = false
            return
        }

        isReconnecting = true
        reconnectAttempts += 1

        // Exponential backoff: 1s, 2s, 4s
        let delay = pow(2.0, Double(reconnectAttempts - 1))
        logger.info("Reconnection attempt \(self.reconnectAttempts)/\(self.maxReconnectAttempts) in \(delay)s")

        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        // Check if we've been cancelled or manually disconnected
        guard lastConnectionURL != nil, !connected else {
            isReconnecting = false
            return
        }

        await performConnect(url: url, token: token)

        // If still not connected, try again
        if !connected && reconnectAttempts < maxReconnectAttempts {
            await attemptReconnect()
        } else if !connected {
            isReconnecting = false
            logger.error("Failed to reconnect after \(self.maxReconnectAttempts) attempts")
        }
    }

    /// Request a fresh token and reconnect (for token expiry handling)
    func refreshConnection(newToken: String) async {
        guard let url = lastConnectionURL else { return }

        lastConnectionToken = newToken
        reconnectAttempts = 0

        if connected {
            await disconnect()
        }

        await performConnect(url: url, token: newToken)
    }

    // MARK: - Audio Session
    private func configureAudioSession() async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [.defaultToSpeaker, .allowBluetoothA2DP, .mixWithOthers]
        )
        try session.setActive(true)
    }

    // MARK: - Remote Audio Monitoring
    private func startRemoteAudioMonitoring() {
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateRemoteAudioLevel()
            }
        }
    }

    private func stopRemoteAudioMonitoring() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
        remoteAudioLevel = 0
    }

    private func updateRemoteAudioLevel() {
        guard let room = room else {
            remoteAudioLevel = 0
            return
        }

        // Check if any remote participant is speaking
        let isSpeaking = room.remoteParticipants.values.contains { $0.isSpeaking }

        if isSpeaking {
            // Smoothly increase with slight variation for natural feel
            let target: Float = 0.6 + Float.random(in: 0...0.3)
            remoteAudioLevel = remoteAudioLevel * 0.7 + target * 0.3
        } else {
            // Smoothly decrease
            remoteAudioLevel = remoteAudioLevel * 0.85
            if remoteAudioLevel < 0.05 {
                remoteAudioLevel = 0
            }
        }
    }

    // MARK: - Cleanup
    deinit {
        audioLevelTimer?.invalidate()
        networkCancellable?.cancel()
    }
}
