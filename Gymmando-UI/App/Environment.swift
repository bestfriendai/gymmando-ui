import Foundation

/// Environment configuration for different build targets
enum AppEnvironment {
    case development
    case staging
    case production

    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    var tokenAPIURL: String {
        switch self {
        case .development:
            return "https://gymmando-api-cjpxcek7oa-uc.a.run.app/token"
        case .staging:
            return "https://gymmando-api-staging.a.run.app/token"
        case .production:
            return "https://gymmando-api-cjpxcek7oa-uc.a.run.app/token"
        }
    }

    var liveKitURL: String {
        switch self {
        case .development, .staging, .production:
            return "wss://gymbo-li7l0in9.livekit.cloud"
        }
    }

    var defaultRoomName: String {
        return "gym-room"
    }
}

/// Centralized configuration
enum AppConfig {
    static let environment = AppEnvironment.current

    enum API {
        static var tokenURL: URL? {
            URL(string: environment.tokenAPIURL)
        }
        static var liveKitURL: String {
            environment.liveKitURL
        }
        static var roomName: String {
            environment.defaultRoomName
        }
    }

    enum Timeouts {
        static let apiRequest: TimeInterval = 30
        static let liveKitConnection: TimeInterval = 15
    }

    enum Animation {
        static let standard: Double = 0.3
        static let quick: Double = 0.15
        static let slow: Double = 0.5
    }
}
