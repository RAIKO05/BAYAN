import AppIntents
import Foundation

// MARK: - 1-Tap Quran Audio Recognition Intent
public struct RecognizeQuranIntent: AppIntent {
    public static var title: LocalizedStringResource = "Identify Quran Recitation"
    public static var description = IntentDescription("Starts listening to identify the Surah, Ayah, and Reciter with Bayan.")
    public static var openAppWhenRun: Bool = true

    public init() {}

    public func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.tools.rea.Bayan") ?? UserDefaults.standard
        defaults.set(true, forKey: "bayan_trigger_identify_on_launch")
        return .result()
    }
}
