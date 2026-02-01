import Foundation
@testable import SkylightApp

final class MockKeychainManager: KeychainManagerProtocol {
    private var accessToken: String?
    private var refreshToken: String?
    private var userId: String?

    var saveAccessTokenCalled = false
    var saveRefreshTokenCalled = false
    var saveUserIdCalled = false
    var clearAllCalled = false

    func saveAccessToken(_ token: String) -> Bool {
        saveAccessTokenCalled = true
        accessToken = token
        return true
    }

    func getAccessToken() -> String? {
        return accessToken
    }

    func saveRefreshToken(_ token: String) -> Bool {
        saveRefreshTokenCalled = true
        refreshToken = token
        return true
    }

    func getRefreshToken() -> String? {
        return refreshToken
    }

    func saveUserId(_ userId: String) -> Bool {
        saveUserIdCalled = true
        self.userId = userId
        return true
    }

    func getUserId() -> String? {
        return userId
    }

    func clearAll() {
        clearAllCalled = true
        accessToken = nil
        refreshToken = nil
        userId = nil
    }

    func reset() {
        clearAll()
        saveAccessTokenCalled = false
        saveRefreshTokenCalled = false
        saveUserIdCalled = false
        clearAllCalled = false
    }

    // Helper to set up initial state for testing
    func setupAuthenticated(token: String = "test-token", userId: String = "test-user-id") {
        self.accessToken = token
        self.userId = userId
    }
}
