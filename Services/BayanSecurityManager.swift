import Foundation
import SwiftUI
import LocalAuthentication
import UIKit

// MARK: - Bayan Security & Privacy Shield Manager
@Observable
public final class BayanSecurityManager {
    public static let shared = BayanSecurityManager()

    // Persistent Security Keys
    private let kBiometricLockEnabledKey = "bayan_security_biometric_lock_enabled"
    private let kAutoLockTimeoutMinutesKey = "bayan_security_autolock_timeout"
    private let kPrivacyShieldEnabledKey = "bayan_security_privacy_shield_enabled"
    private let kLastBackgroundTimestampKey = "bayan_security_last_background_timestamp"

    private let userDefaults = UserDefaults.standard

    // Public Observable States
    public var isBiometricLockEnabled: Bool = false {
        didSet {
            userDefaults.set(isBiometricLockEnabled, forKey: kBiometricLockEnabledKey)
            if !isBiometricLockEnabled {
                isAppLocked = false
            }
        }
    }

    public var isPrivacyShieldEnabled: Bool = true {
        didSet {
            userDefaults.set(isPrivacyShieldEnabled, forKey: kPrivacyShieldEnabledKey)
        }
    }

    public var autoLockTimeoutMinutes: Int = 1 {
        didSet {
            userDefaults.set(autoLockTimeoutMinutes, forKey: kAutoLockTimeoutMinutesKey)
        }
    }

    public var isAppLocked: Bool = false
    public var isPrivacyShieldActive: Bool = false
    public var authenticationErrorMessage: String? = nil

    public enum BiometricType {
        case faceID
        case touchID
        case opticID
        case none

        public var title: String {
            switch self {
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            case .opticID: return "Optic ID"
            case .none: return "Device Passcode"
            }
        }

        public var iconName: String {
            switch self {
            case .faceID: return "faceid"
            case .touchID: return "touchid"
            case .opticID: return "eye.circle.fill"
            case .none: return "lock.fill"
            }
        }
    }

    public var supportedBiometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        @unknown default: return .none
        }
    }

    private init() {
        self.isBiometricLockEnabled = userDefaults.bool(forKey: kBiometricLockEnabledKey)
        let storedTimeout = userDefaults.integer(forKey: kAutoLockTimeoutMinutesKey)
        self.autoLockTimeoutMinutes = storedTimeout > 0 ? storedTimeout : 1
        self.isPrivacyShieldEnabled = userDefaults.object(forKey: kPrivacyShieldEnabledKey) != nil ? userDefaults.bool(forKey: kPrivacyShieldEnabledKey) : true

        if isBiometricLockEnabled {
            self.isAppLocked = true
        }

        setupLifecycleObservers()
        hardenStorageDirectories()
    }

    // MARK: - Lifecycle Notifications for Privacy Shield & Auto-Lock
    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func handleAppWillResignActive() {
        if isPrivacyShieldEnabled {
            withAnimation(.easeInOut(duration: 0.15)) {
                self.isPrivacyShieldActive = true
            }
        }
    }

    @objc private func handleAppDidEnterBackground() {
        userDefaults.set(Date().timeIntervalSince1970, forKey: kLastBackgroundTimestampKey)
        if isBiometricLockEnabled && autoLockTimeoutMinutes == 0 {
            self.isAppLocked = true
        }
    }

    @objc private func handleAppDidBecomeActive() {
        if isBiometricLockEnabled {
            let lastBackground = userDefaults.double(forKey: kLastBackgroundTimestampKey)
            if lastBackground > 0 {
                let elapsedMinutes = (Date().timeIntervalSince1970 - lastBackground) / 60.0
                if elapsedMinutes >= Double(autoLockTimeoutMinutes) {
                    self.isAppLocked = true
                }
            }
        }

        // Deactivate privacy shield if app is not locked
        if !isAppLocked {
            withAnimation(.easeInOut(duration: 0.25)) {
                self.isPrivacyShieldActive = false
            }
        }
    }

    // MARK: - Biometric Authentication Flow
    @MainActor
    public func authenticateUser(reason: String = "Unlock Bayan to access your Quran bookmarks and prayer journal.") async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            self.authenticationErrorMessage = error?.localizedDescription ?? "Biometrics unavailable on this device."
            return false
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )

            if success {
                self.isAppLocked = false
                self.isPrivacyShieldActive = false
                self.authenticationErrorMessage = nil
                #if os(iOS)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
                return true
            } else {
                self.authenticationErrorMessage = "Authentication failed."
                return false
            }
        } catch {
            self.authenticationErrorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Hardware Storage Hardening & File Protection
    public func hardenStorageDirectories() {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let documents = fm.urls(for: .documentDirectory, in: .userDomainMask)

        for dir in (appSupport + documents) {
            try? fm.setAttributes(
                [FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: dir.path
            )
        }
    }

    public func excludeFromBackup(url: URL) {
        var mutableUrl = url
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try? mutableUrl.setResourceValues(resourceValues)
    }
}
