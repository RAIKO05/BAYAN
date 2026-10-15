import AppIntents
import SwiftUI

// MARK: - 1-Tap Quran Audio Recognition Intent
public struct RecognizeQuranIntent: AppIntent {
    public static var title: LocalizedStringResource = "Identify Quran Recitation"
    public static var description = IntentDescription("Starts listening to identify the Surah, Ayah, and Reciter with Bayan.")
    public static var openAppWhenRun: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        // Deep-links directly to the listening radar orb
        if let url = URL(string: "bayan://identify") {
            await UIApplication.shared.open(url)
        }
        return .result()
    }
}
