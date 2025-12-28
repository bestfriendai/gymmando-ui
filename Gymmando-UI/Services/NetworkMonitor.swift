import Foundation
import Network
import Combine

/// Network connection status
enum NetworkStatus: Equatable {
    case connected
    case disconnected
    case unknown

    var isConnected: Bool {
        self == .connected
    }

    var statusMessage: String {
        switch self {
        case .connected:
            return "Connected"
        case .disconnected:
            return "No internet connection"
        case .unknown:
            return "Checking connection..."
        }
    }
}

/// Monitors network connectivity
@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var status: NetworkStatus = .unknown
    @Published private(set) var connectionType: NWInterface.InterfaceType?
    @Published private(set) var isExpensive: Bool = false
    @Published private(set) var isConstrained: Bool = false

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.gymmando.networkmonitor")

    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateStatus(from: path)
            }
        }
        monitor.start(queue: queue)
    }

    private func updateStatus(from path: NWPath) {
        // Update connection status
        switch path.status {
        case .satisfied:
            status = .connected
        case .unsatisfied:
            status = .disconnected
        case .requiresConnection:
            status = .unknown
        @unknown default:
            status = .unknown
        }

        // Update connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else {
            connectionType = nil
        }

        // Update expensive/constrained flags
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
    }

    deinit {
        monitor.cancel()
    }
}

// MARK: - Network Status Banner View
import SwiftUI

struct NetworkStatusBanner: View {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @State private var showBanner = false

    var body: some View {
        VStack {
            if showBanner && !networkMonitor.status.isConnected {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: DesignTokens.IconSize.sm))

                    Text(networkMonitor.status.statusMessage)
                        .font(DesignTokens.Typography.labelMedium)

                    Spacer()

                    Button {
                        // Could trigger a retry action here
                        HapticManager.shared.impact(style: .light)
                    } label: {
                        Text("Retry")
                            .font(DesignTokens.Typography.labelMedium)
                            .foregroundColor(Color.App.primary)
                    }
                }
                .foregroundColor(.white)
                .padding(DesignTokens.Spacing.md)
                .background(Color.App.error)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showBanner)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: networkMonitor.status)
        .onChange(of: networkMonitor.status) { _, newStatus in
            withAnimation {
                showBanner = !newStatus.isConnected
            }

            // Announce to VoiceOver
            if !newStatus.isConnected {
                AccessibilityAnnouncement.announce("No internet connection")
            } else if showBanner {
                AccessibilityAnnouncement.announce("Connected to internet")
                // Hide banner after reconnection with delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showBanner = false
                    }
                }
            }
        }
        .onAppear {
            showBanner = !networkMonitor.status.isConnected
        }
    }
}

// MARK: - Offline View
struct OfflineView: View {
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            // Icon
            Image(systemName: "wifi.slash")
                .font(.system(size: 80, weight: .light))
                .foregroundColor(Color.App.textTertiary)

            // Message
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("No Internet Connection")
                    .font(DesignTokens.Typography.headlineSmall)
                    .foregroundColor(Color.App.textPrimary)

                Text("Please check your connection and try again")
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(Color.App.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Retry Button
            Button(action: {
                HapticManager.shared.impact(style: .medium)
                retryAction()
            }) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(width: 200)

            Spacer()
        }
        .padding(DesignTokens.Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No internet connection. Double tap to retry.")
    }
}

// MARK: - View Modifier for Network Awareness
struct NetworkAwareModifier: ViewModifier {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    let showBanner: Bool

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            if showBanner {
                NetworkStatusBanner()
            }
            content
        }
    }
}

extension View {
    /// Adds network status awareness to a view
    func networkAware(showBanner: Bool = true) -> some View {
        modifier(NetworkAwareModifier(showBanner: showBanner))
    }
}

// MARK: - Preview
#Preview("Offline View") {
    OfflineView {
        print("Retry tapped")
    }
    .background(Color.App.background)
}

#Preview("Network Banner") {
    VStack {
        NetworkStatusBanner()
        Spacer()
    }
    .background(Color.App.background)
}
