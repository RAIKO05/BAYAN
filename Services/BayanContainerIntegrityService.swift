import Foundation
import DeviceCheck
import CryptoKit

// MARK: - Bayan Container Integrity & Anti-Piracy Attestation Service
/// Hardened security layer enforcing:
/// 1. Hardware App Attest / DeviceCheck cryptographic key generation
/// 2. Outbound request attestation receipts with single-use challenge hashes
/// 3. Dynamic Bundle Identifier & Code Signing container integrity validation
/// 4. Anti-Tamper & Sideloaded IPA detection
public final class BayanContainerIntegrityService {
    public static let shared = BayanContainerIntegrityService()

    // Authorized Bundle Identifiers (Official App Store & Enterprise Team namespaces)
    private let authorizedBundleIdentifiers: Set<String> = [
        "tools.rea.Bayan",
        "com.bayan.app"
    ]

    // Keychain key for stored App Attest Key ID
    private let kAttestKeyIdStorage = "bayan_devicecheck_attest_key_id"

    // Runtime Container Integrity State
    public private(set) var isContainerCompromised: Bool = false
    public private(set) var containerViolationDetails: String? = nil
    public private(set) var currentAttestationKeyId: String? = nil

    private init() {
        verifyContainerIntegrity()
        Task {
            await initializeAppAttestKey()
        }
    }

    // MARK: - 1. Container & Bundle ID Validation
    @discardableResult
    public func verifyContainerIntegrity() -> Bool {
        // Step A: Dynamic Bundle Identifier Mismatch Check
        guard let currentBundleId = Bundle.main.bundleIdentifier else {
            flagViolation("Bundle identifier is missing from runtime bundle.")
            return false
        }

        if !authorizedBundleIdentifiers.contains(currentBundleId) {
            flagViolation("Unauthorized Bundle Identifier detected: '\(currentBundleId)'. Expected authorized namespace.")
            return false
        }

        // Step B: Executable Info Dictionary Check
        guard let infoDict = Bundle.main.infoDictionary else {
            flagViolation("Main bundle info dictionary is missing or inaccessible.")
            return false
        }

        let bundleName = infoDict["CFBundleName"] as? String ?? ""
        if bundleName.isEmpty {
            flagViolation("Executable bundle name has been stripped or modified.")
            return false
        }

        // Step C: Provisioning Profile Anomaly Inspection
        if let provisionPath = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") {
            if let provisionData = try? Data(contentsOf: URL(fileURLWithPath: provisionPath)) {
                let provisionString = String(decoding: provisionData, as: UTF8.self)
                // Detect cracked pirate resigning and injected distribution signatures
                let pirateSignatures = ["appdb_cracked", "iosgods", "pandahelper", "tutubox", "cydiaimpactor_mod"]
                let lowerProvision = provisionString.lowercased()
                for sig in pirateSignatures {
                    if lowerProvision.contains(sig) {
                        flagViolation("Unauthorized pirate resigning profile detected: '\(sig)'.")
                        return false
                    }
                }
            }
        }

        return true
    }

    private func flagViolation(_ reason: String) {
        self.isContainerCompromised = true
        self.containerViolationDetails = reason
        #if DEBUG
        print("⚠️ [ContainerIntegrity] VIOLATION: \(reason)")
        #endif
    }

    // MARK: - 2. DeviceCheck / App Attest Key Lifecycle
    public func initializeAppAttestKey() async {
        let service = DCAppAttestService.shared
        guard service.isSupported else {
            #if DEBUG
            print("ℹ️ [AppAttest] DCAppAttestService not supported on this architecture (Simulator/Old Device).")
            #endif
            return
        }

        // Retrieve existing key ID or generate fresh hardware-backed key
        if let storedKeyId = BayanKeychainService.shared.getString(forKey: kAttestKeyIdStorage) {
            self.currentAttestationKeyId = storedKeyId
            return
        }

        do {
            let keyId = try await service.generateKey()
            self.currentAttestationKeyId = keyId
            BayanKeychainService.shared.set(string: keyId, forKey: kAttestKeyIdStorage)
        } catch {
            #if DEBUG
            print("⚠️ [AppAttest] Key generation warning: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - 3. Outbound Network Attestation & Challenge Signing
    /// Injects cryptographically verifiable attestation headers into outbound network calls
    public func attestRequestHeaders(for url: URL, payloadData: Data? = nil) async -> [String: String] {
        var headers: [String: String] = [:]

        // A. Dynamic Single-Use Nonce
        let timestamp = String(format: "%.0f", Date().timeIntervalSince1970 * 1000)
        let randomNonce = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        headers["X-Bayan-Timestamp"] = timestamp
        headers["X-Bayan-Nonce"] = randomNonce

        // B. Container Integrity Header
        headers["X-Bayan-Container-Valid"] = isContainerCompromised ? "0" : "1"

        // C. Client Challenge Hash: SHA256(URL + Nonce + Payload + Salt)
        let salt = "Bayan_Attest_Salt_v1"
        var challengeString = "\(url.absoluteString)|\(timestamp)|\(randomNonce)|\(salt)"
        if let payload = payloadData {
            let payloadHash = SHA256.hash(data: payload).compactMap { String(format: "%02x", $0) }.joined()
            challengeString += "|\(payloadHash)"
        }

        let challengeHash = SHA256.hash(data: Data(challengeString.utf8)).compactMap { String(format: "%02x", $0) }.joined()
        headers["X-Bayan-Challenge-Hash"] = challengeHash

        // D. Hardware DeviceCheck Assertion (if key exists)
        if let keyId = currentAttestationKeyId, DCAppAttestService.shared.isSupported {
            headers["X-Bayan-Attest-Key-ID"] = keyId
            let clientDataHash = Data(SHA256.hash(data: Data(challengeHash.utf8)))
            if let assertion = try? await DCAppAttestService.shared.generateAssertion(keyId, clientDataHash: clientDataHash) {
                headers["X-Bayan-Attest-Assertion"] = assertion.base64EncodedString()
            }
        }

        return headers
    }
}
