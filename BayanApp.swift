import SwiftUI

@main
struct BayanApp: App {
    @State private var syncManager = QuranSyncManager.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
        }
    }
}
