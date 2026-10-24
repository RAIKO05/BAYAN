import Foundation
import SwiftUI
import AuthenticationServices

public enum AuthProvider: String, Codable, CaseIterable {
    case apple = "Apple"
    case google = "Google"
    case email = "Email"

    public var iconName: String {
        switch self {
        case .apple: return "apple.logo"
        case .google: return "globe"
        case .email: return "envelope.fill"
        }
    }
}

public struct BayanUser: Codable, Equatable {
    public let id: String
    public var email: String
    public var name: String
    public var provider: AuthProvider
    public var avatarEmoji: String

    public init(id: String, email: String, name: String, provider: AuthProvider, avatarEmoji: String = "👑") {
        self.id = id
        self.email = email
        self.name = name
        self.provider = provider
        self.avatarEmoji = avatarEmoji
    }
}

@Observable
public final class BayanAuthService: NSObject {
    public static let shared = BayanAuthService()

    private let keychain = BayanKeychainService.shared
    private let encryption = BayanDataEncryptionService.shared
    private let kSecureUserKey = "bayan_secure_auth_user_aes256"
    private let kIsSignedInKey = "bayan_auth_is_signed_in"
    private let kLegacyUserKey = "bayan_auth_user_data"

    public var isSignedIn: Bool = false
    public var currentUser: BayanUser? = nil

    override private init() {
        super.init()
        loadSecureSession()
    }

    private func loadSecureSession() {
        // 1. Attempt reading from hardware-isolated Keychain (AES-256 Encrypted)
        if let encryptedData = keychain.getData(forKey: kSecureUserKey),
           let user = try? encryption.decryptCodable(BayanUser.self, from: encryptedData) {
            self.currentUser = user
            self.isSignedIn = true
            return
        }

        // 2. Seamless Migration: If legacy plaintext exists in UserDefaults, encrypt into Keychain and purge plaintext
        if let legacyData = UserDefaults.standard.data(forKey: kLegacyUserKey),
           let user = try? JSONDecoder().decode(BayanUser.self, from: legacyData) {
            self.currentUser = user
            self.isSignedIn = true
            if let encrypted = try? encryption.encryptCodable(user) {
                keychain.set(data: encrypted, forKey: kSecureUserKey)
            }
            // Purge plaintext from UserDefaults for privacy
            UserDefaults.standard.removeObject(forKey: kLegacyUserKey)
        } else {
            self.isSignedIn = UserDefaults.standard.bool(forKey: kIsSignedInKey)
        }
    }

    // MARK: - Sign In with Apple
    public func signInWithApple(credential: ASAuthorizationAppleIDCredential? = nil) {
        let userId = credential?.user ?? UUID().uuidString
        var displayName = "Muslim Companion"
        if let fullName = credential?.fullName {
            let given = fullName.givenName ?? ""
            let family = fullName.familyName ?? ""
            let combined = "\(given) \(family)".trimmingCharacters(in: .whitespaces)
            if !combined.isEmpty {
                displayName = combined
            }
        }
        let email = credential?.email ?? "apple.user@privaterelay.appleid.com"

        let user = BayanUser(
            id: userId,
            email: email,
            name: displayName,
            provider: .apple,
            avatarEmoji: "👑"
        )
        completeSignIn(user: user)
    }

    // MARK: - Sign In with Google / Gmail
    public func signInWithGoogle(email: String = "user@gmail.com", name: String = "Google Companion") {
        let user = BayanUser(
            id: UUID().uuidString,
            email: email,
            name: name,
            provider: .google,
            avatarEmoji: "🌙"
        )
        completeSignIn(user: user)
    }

    // MARK: - Sign In with Email
    public func signInWithEmail(email: String, name: String) {
        let user = BayanUser(
            id: UUID().uuidString,
            email: email,
            name: name.isEmpty ? email.components(separatedBy: "@").first ?? "Companion" : name,
            provider: .email,
            avatarEmoji: "🕋"
        )
        completeSignIn(user: user)
    }

    // MARK: - Complete Sign In & Sync Profile
    private func completeSignIn(user: BayanUser) {
        self.currentUser = user
        self.isSignedIn = true

        UserDefaults.standard.set(true, forKey: kIsSignedInKey)
        // Encrypt credentials with AES-256 and store in hardware Keychain
        if let encrypted = try? encryption.encryptCodable(user) {
            keychain.set(data: encrypted, forKey: kSecureUserKey)
        }
        // Purge plaintext from UserDefaults
        UserDefaults.standard.removeObject(forKey: kLegacyUserKey)

        // Sync with BayanSocialService profile
        let social = BayanSocialService.shared
        social.profile.name = user.name
        social.profile.avatarEmoji = user.avatarEmoji
        let cleanHandle = "@" + user.name.lowercased().replacingOccurrences(of: " ", with: "_")
        social.profile.handle = cleanHandle

        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    // MARK: - Sign Out
    public func signOut() {
        self.isSignedIn = false
        self.currentUser = nil
        UserDefaults.standard.set(false, forKey: kIsSignedInKey)
        UserDefaults.standard.removeObject(forKey: kLegacyUserKey)
        keychain.delete(forKey: kSecureUserKey)

        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}
