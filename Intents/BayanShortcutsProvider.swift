import AppIntents

public struct BayanShortcutsProvider: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecognizeQuranIntent(),
            phrases: [
                "Identify Quran with \(.applicationName)",
                "Identify recitation in \(.applicationName)",
                "Recognize Quran with \(.applicationName)",
                "What Surah is this in \(.applicationName)?",
                "Who is reciting in \(.applicationName)?"
            ],
            shortTitle: "Identify Quran",
            systemImageName: "waveform.circle.fill"
        )

        AppShortcut(
            intent: GetPrayerTimeIntent(prayer: .next),
            phrases: [
                "When is next prayer in \(.applicationName)",
                "Next prayer with \(.applicationName)",
                "Prayer times in \(.applicationName)",
                "When to pray with \(.applicationName)"
            ],
            shortTitle: "Next Prayer",
            systemImageName: "clock.badge.checkmark.fill"
        )

        AppShortcut(
            intent: GetPrayerTimeIntent(prayer: .maghrib),
            phrases: [
                "When is Maghrib with \(.applicationName)",
                "When is Maghrib in \(.applicationName)",
                "Maghrib time with \(.applicationName)"
            ],
            shortTitle: "Maghrib Time",
            systemImageName: "sunset.fill"
        )

        AppShortcut(
            intent: GetPrayerTimeIntent(prayer: .fajr),
            phrases: [
                "When is Fajr with \(.applicationName)",
                "When is Fajr in \(.applicationName)",
                "Fajr time with \(.applicationName)"
            ],
            shortTitle: "Fajr Time",
            systemImageName: "sun.haze.fill"
        )

        AppShortcut(
            intent: GetQiblaIntent(),
            phrases: [
                "Where is the Qibla in \(.applicationName)",
                "Qibla direction with \(.applicationName)",
                "Which way is Qibla in \(.applicationName)"
            ],
            shortTitle: "Qibla Direction",
            systemImageName: "safari.fill"
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
