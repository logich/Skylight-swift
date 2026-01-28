import Foundation

enum Constants {
    enum API {
        static let baseURL = "https://api.ourskylight.com"
        static let apiVersion = "v1"
        static let timeout: TimeInterval = 30.0
    }

    enum Keychain {
        static let serviceName = "com.skylightapp.keychain"
        static let accessTokenKey = "accessToken"
        static let refreshTokenKey = "refreshToken"
        static let userIdKey = "userId"
    }

    enum UserDefaults {
        static let selectedFrameIdKey = "selectedFrameId"
        static let selectedFrameNameKey = "selectedFrameName"
        static let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    }

    enum DateFormats {
        static let iso8601Full = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        static let iso8601 = "yyyy-MM-dd'T'HH:mm:ssZ"
        static let dateOnly = "yyyy-MM-dd"
        static let displayDate = "MMM d, yyyy"
        static let displayTime = "h:mm a"
        static let displayDateTime = "MMM d, yyyy 'at' h:mm a"
    }
}
