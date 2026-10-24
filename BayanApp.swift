import SwiftUI

@main
struct BayanApp: App {
    @State private var syncManager = QuranSyncManager.shared
    @State private var cloudSync = BayanCloudSyncService.shared
    @State private var securityManager = BayanSecurityManager.shared

    init() {
        // Silent runtime integrity and anti-piracy container validation
        _ = BayanRuntimeIntegrityGuard.shared
        _ = BayanContainerIntegrityService.shared
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()

                if securityManager.isAppLocked || securityManager.isPrivacyShieldActive {
                    BayanSecurityLockOverlayView()
                        .transition(.opacity)
                        .zIndex(9999)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: securityManager.isAppLocked)
            .animation(.easeInOut(duration: 0.15), value: securityManager.isPrivacyShieldActive)
            .preferredColorScheme(.dark)
        }
    }
}
