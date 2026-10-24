import Foundation
import Security

// MARK: - Bayan Hardware-Backed Keychain Service
/// Secure, hardware-isolated storage for encryption keys, user credentials, and biometric tokens.
/// Protected with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` so items cannot be
/// read off a locked device or transferred via unencrypted device backups.
public final class BayanKeychainService {
    public static let shared = BayanKeychainService()

    private let serviceIdentifier = "com.bayan.app.keychain"

    private init() {}

    // MARK: - Generic Data Storage
    public func set(data: Data, forKey key: String) -> Bool {
        // Delete any existing item first
        delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    public func getData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        return data
    }

    @discardableResult
    public func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - String Convenience
    public func set(string: String, forKey key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return set(data: data, forKey: key)
    }

    public func getString(forKey key: String) -> String? {
        guard let data = getData(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Codable Convenience
    public func setCodable<T: Encodable>(_ value: T, forKey key: String) -> Bool {
        guard let data = try? JSONEncoder().encode(value) else { return false }
        return set(data: data, forKey: key)
    }

    public func getCodable<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = getData(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
