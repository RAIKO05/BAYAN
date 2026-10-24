import Foundation
import CryptoKit

// MARK: - Bayan High-Grade AES-256-GCM Data Encryption Service
/// Enterprise-grade symmetric cryptographic engine using Apple's hardware-accelerated CryptoKit.
/// Employs 256-bit AES-GCM (Galois/Counter Mode) authenticated encryption with associated data (AEAD),
/// random 96-bit nonces, and 128-bit authentication tags to prevent data tampering, inspection, or replay.
public final class BayanDataEncryptionService {
    public static let shared = BayanDataEncryptionService()

    private let keychain = BayanKeychainService.shared
    private let masterKeyIdentifier = "bayan_master_aes256_encryption_key_v1"

    public enum EncryptionError: LocalizedError {
        case keyGenerationFailed
        case encryptionFailed
        case decryptionFailed
        case dataCorrupted
        case encodingFailed

        public var errorDescription: String? {
            switch self {
            case .keyGenerationFailed: return "Failed to generate or retrieve secure AES-256 master key."
            case .encryptionFailed: return "Hardware AES-GCM encryption encountered an unexpected error."
            case .decryptionFailed: return "Decryption failed: data was tampered with or key is invalid."
            case .dataCorrupted: return "Encrypted payload envelope is malformed or corrupted."
            case .encodingFailed: return "Failed to encode object to binary payload for encryption."
            }
        }
    }

    private init() {}

    // MARK: - Master Key Management (Hardware Keychain Isolation)
    private func getOrCreateMasterKey() throws -> SymmetricKey {
        if let keyData = keychain.getData(forKey: masterKeyIdentifier) {
            return SymmetricKey(data: keyData)
        }

        // Generate cryptographically secure 256-bit random key
        let newKey = SymmetricKey(size: .bits256)
        let rawData = newKey.withUnsafeBytes { Data($0) }
        guard keychain.set(data: rawData, forKey: masterKeyIdentifier) else {
            throw EncryptionError.keyGenerationFailed
        }
        return newKey
    }

    // MARK: - Core AES-256-GCM Encryption
    /// Encrypts raw data using AES-GCM 256-bit with an authenticated sealed box
    public func encrypt(_ data: Data) throws -> Data {
        let key = try getOrCreateMasterKey()
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            guard let combined = sealedBox.combined else {
                throw EncryptionError.encryptionFailed
            }
            return combined
        } catch {
            throw EncryptionError.encryptionFailed
        }
    }

    /// Decrypts an authenticated AES-GCM sealed box back to plaintext
    public func decrypt(_ sealedData: Data) throws -> Data {
        let key = try getOrCreateMasterKey()
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: sealedData)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            throw EncryptionError.decryptionFailed
        }
    }

    // MARK: - Codable Encryption Convenience
    public func encryptCodable<T: Encodable>(_ object: T) throws -> Data {
        guard let plainData = try? JSONEncoder().encode(object) else {
            throw EncryptionError.encodingFailed
        }
        return try encrypt(plainData)
    }

    public func decryptCodable<T: Decodable>(_ type: T.Type, from encryptedData: Data) throws -> T {
        let plainData = try decrypt(encryptedData)
        guard let decoded = try? JSONDecoder().decode(type, from: plainData) else {
            throw EncryptionError.dataCorrupted
        }
        return decoded
    }

    // MARK: - Cryptographic Integrity Verification (SHA-256)
    public func sha256Checksum(of data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Encrypted File Storage Helper
    public func writeEncrypted(data: Data, to fileURL: URL) throws {
        let encrypted = try encrypt(data)
        try encrypted.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    public func readEncrypted(from fileURL: URL) throws -> Data {
        let encryptedData = try Data(contentsOf: fileURL)
        return try decrypt(encryptedData)
    }
}
