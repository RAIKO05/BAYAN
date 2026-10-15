import AppIntents

public struct BayanShortcutsProvider: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecognizeQuranIntent(),
            phrases: [
                "Identify this Surah with \(.applicationName)",
                "Recognize Quran with \(.applicationName)",
                "Who is reciting in \(.applicationName)?",
                "What Surah is this in \(.applicationName)?"
            ],
            shortTitle: "Identify Quran",
            systemImageName: "waveform.circle.fill"
        )

        AppShortcut(
            intent: ResumeQuranIntent(),
            phrases: [
                "Resume Quran in \(.applicationName)",
                "Continue reading Quran with \(.applicationName)",
                "Where did I stop reading in \(.applicationName)?"
            ],
            shortTitle: "Resume Reading",
            systemImageName: "book.pages.fill"
        )
    }
}
