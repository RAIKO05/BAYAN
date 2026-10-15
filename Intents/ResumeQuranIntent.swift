import AppIntents
import SwiftUI

// MARK: - Resume Last Read Position Intent
public struct ResumeQuranIntent: AppIntent {
    public static var title: LocalizedStringResource = "Resume Quran Reading"
    public static var description = IntentDescription("Resumes reading the Holy Quran from where you stopped last time.")
    public static var openAppWhenRun: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        if let url = URL(string: "bayan://resume") {
            await UIApplication.shared.open(url)
        }
        return .result()
    }
}
