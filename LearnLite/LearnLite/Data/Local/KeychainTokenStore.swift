import Foundation
import Security

protocol TokenStore {
    func token() -> String?
    func save(token: String) throws
    func deleteToken()
}

enum KeychainError: Error, Equatable {
    case unhandled(OSStatus)
}

/// Stores the session token in the iOS Keychain (never in UserDefaults).
final class KeychainTokenStore: TokenStore {
    private let service: String
    private let account = "session-token"

    init(service: String = "com.avinash.LearnLite.session") {
        self.service = service
    }

    func token() -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func save(token: String) throws {
        deleteToken()

        var attributes = baseQuery()
        attributes[kSecValueData as String] = Data(token.utf8)
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status)
        }
    }

    func deleteToken() {
        SecItemDelete(baseQuery() as CFDictionary)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
