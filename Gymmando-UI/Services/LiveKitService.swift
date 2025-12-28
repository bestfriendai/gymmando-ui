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

    // MARK: - Private Properties
    private var room: Room?
    private var audioLevelTimer: Timer?
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Gymmando", category: "LiveKit")

    // MARK: - Connection
    func connect(url: String, token: String) async {
        // Disconnect any existing connection first
        if room != nil {
            await disconnect()
        }

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
            startRemoteAudioMonitoring()

            logger.info("Successfully connected to LiveKit room")

        } catch {
            logger.error("Failed to connect: \(error.localizedDescription)")
            connected = false
            room = nil
        }
    }

    func disconnect() async {
        stopRemoteAudioMonitoring()

        guard let room = self.room else { return }

        try? await room.localParticipant.setMicrophone(enabled: false)
        await room.disconnect()

        self.connected = false
        self.room = nil

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        logger.info("Disconnected from LiveKit room")
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
    }
}
