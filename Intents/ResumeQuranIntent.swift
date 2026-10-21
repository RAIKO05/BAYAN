import AppIntents
import Foundation

// MARK: - Resume Last Read Position Intent
public struct ResumeQuranIntent: AppIntent {
    public static var title: LocalizedStringResource = "Resume Quran Reading"
    public static var description = IntentDescription("Resumes reading the Holy Quran from where you stopped last time.")
    public static var openAppWhenRun: Bool = true

    public init() {}

    public func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.tools.rea.Bayan") ?? UserDefaults.standard
        defaults.set(true, forKey: "bayan_trigger_resume_on_launch")
        return .result()
    }
}
