import Foundation
import Security

protocol KeychainManagerProtocol {
    func saveAccessToken(_ token: String) -> Bool
    func getAccessToken() -> String?
    func saveRefreshToken(_ token: String) -> Bool
    func getRefreshToken() -> String?
    func saveUserId(_ userId: String) -> Bool
    func getUserId() -> String?
    func clearAll()
}

final class KeychainManager: KeychainManagerProtocol {
    static let shared = KeychainManager()

    private let serviceName = Constants.Keychain.serviceName

    private init() {}

    // MARK: - Access Token

    func saveAccessToken(_ token: String) -> Bool {
        save(token, forKey: Constants.Keychain.accessTokenKey)
    }

    func getAccessToken() -> String? {
        get(forKey: Constants.Keychain.accessTokenKey)
    }

    // MARK: - Refresh Token

    func saveRefreshToken(_ token: String) -> Bool {
        save(token, forKey: Constants.Keychain.refreshTokenKey)
    }

    func getRefreshToken() -> String? {
        get(forKey: Constants.Keychain.refreshTokenKey)
    }

    // MARK: - User ID

    func saveUserId(_ userId: String) -> Bool {
        save(userId, forKey: Constants.Keychain.userIdKey)
    }

    func getUserId() -> String? {
        get(forKey: Constants.Keychain.userIdKey)
    }

    // MARK: - Clear All

    func clearAll() {
        delete(forKey: Constants.Keychain.accessTokenKey)
        delete(forKey: Constants.Keychain.refreshTokenKey)
        delete(forKey: Constants.Keychain.userIdKey)
    }

    // MARK: - Private Helpers

    private func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }

        // Delete any existing item first
        delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    private func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    @discardableResult
    private func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
