import Foundation
import Security
import os.log

final class KeychainManager {
    static let shared = KeychainManager()

    private let service = "dev.fff.murmurmobile"
    private let apiKeyAccount = "elevenlabs-api-key"
    private let logger = OSLog(subsystem: "dev.fff.murmurmobile", category: "KeychainManager")

    enum KeychainError: Error { case duplicateItem, itemNotFound, authFailed, unknown(OSStatus) }

    private init() {}

    func saveAPIKey(_ apiKey: String) -> Bool {
        deleteAPIKey()
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            os_log("Attempted to save empty API key", log: logger, type: .error)
            return false
        }
        let data = apiKey.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess { os_log("Keychain save error: %d", log: logger, type: .error, status) }
        return status == errSecSuccess
    }

    func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data { return String(data: data, encoding: .utf8) }
        if status != errSecItemNotFound { os_log("Keychain read error: %d", log: logger, type: .error, status) }
        return nil
    }

    @discardableResult
    func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    func hasAPIKey() -> Bool { (getAPIKey() ?? "").isEmpty == false }
}
