import SwiftUI

@main
struct BayanApp: App {
    @State private var syncManager = QuranSyncManager.shared
    @State private var cloudSync = BayanCloudSyncService.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
        }
    }
}
