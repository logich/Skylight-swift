import Foundation
@testable import SkylightApp

/// A mock-friendly wrapper for testing authentication flows
/// Note: Since AuthenticationManager is @MainActor and uses @Published properties,
/// tests should use dependency injection with mock KeychainManager and APIClient
/// rather than trying to mock the entire manager.
///
/// For testing ViewModels that depend on AuthenticationManager, create an
/// instance with injected mocks:
///
/// ```swift
/// let mockKeychain = MockKeychainManager()
/// let mockAPI = MockAPIClient()
/// let authManager = AuthenticationManager(
///     keychainManager: mockKeychain,
///     apiClient: mockAPI,
///     userDefaults: UserDefaults(suiteName: "test")!
/// )
/// ```

extension AuthenticationManager {
    /// Creates an AuthenticationManager configured for testing
    @MainActor
    static func makeForTesting(
        keychainManager: KeychainManagerProtocol = MockKeychainManager(),
        apiClient: APIClientProtocol = MockAPIClient(),
        userDefaults: UserDefaults = UserDefaults(suiteName: "com.test.skylight")!
    ) -> AuthenticationManager {
        // Clear any existing test data
        userDefaults.removePersistentDomain(forName: "com.test.skylight")

        return AuthenticationManager(
            keychainManager: keychainManager,
            apiClient: apiClient,
            userDefaults: userDefaults
        )
    }
}

/// Test helpers for setting up authentication state
extension MockKeychainManager {
    /// Configures the mock to simulate an unauthenticated state
    func setupUnauthenticated() {
        clearAll()
        clearAllCalled = false
    }

    /// Configures the mock to simulate an authenticated state
    func setupAuthenticatedState(token: String = "test-token", userId: String = "test-user-id") {
        _ = saveAccessToken(token)
        _ = saveUserId(userId)
        saveAccessTokenCalled = false
        saveUserIdCalled = false
    }
}
