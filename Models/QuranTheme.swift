import SwiftUI

// MARK: - Quran & App Reading Theme Catalog
/// Comprehensive theme system unifying aesthetics across all Bayan tabs:
/// Modern, Paper, Dark, Emerald, Midnight, and OLED.
public enum QuranTheme: String, CaseIterable, Identifiable, Codable {
    case paper = "Paper"
    case modern = "Modern"
    case dark = "Dark"
    case emerald = "Emerald"
    case midnight = "Midnight"
    case oled = "OLED"

    public var id: String { rawValue }
    public var title: String { rawValue }
    public var name: String { rawValue }

    // MARK: - Preview Box Appearance
    public var previewBackground: Color {
        switch self {
        case .paper:
            return Color(red: 0.98, green: 0.95, blue: 0.88)
        case .modern:
            return Color(red: 0.93, green: 0.94, blue: 0.96)
        case .dark:
            return Color(red: 0.14, green: 0.15, blue: 0.18)
        case .emerald:
            return Color(red: 0.03, green: 0.16, blue: 0.12)
        case .midnight:
            return Color(red: 0.05, green: 0.09, blue: 0.18)
        case .oled:
            return Color(red: 0.02, green: 0.02, blue: 0.02)
        }
    }

    public var previewTextColor: Color {
        switch self {
        case .paper:
            return Color(red: 0.18, green: 0.11, blue: 0.05)
        case .modern:
            return Color(red: 0.10, green: 0.12, blue: 0.16)
        case .dark:
            return .white
        case .emerald:
            return Color(red: 0.90, green: 0.98, blue: 0.92)
        case .midnight:
            return Color(red: 0.92, green: 0.95, blue: 1.00)
        case .oled:
            return .white
        }
    }

    public var previewLabelColor: Color {
        switch self {
        case .paper:
            return Color(red: 0.40, green: 0.28, blue: 0.16)
        case .modern:
            return Color(red: 0.28, green: 0.32, blue: 0.40)
        case .dark:
            return Color(red: 0.85, green: 0.85, blue: 0.87)
        case .emerald:
            return Color(red: 0.35, green: 0.85, blue: 0.60)
        case .midnight:
            return Color(red: 0.55, green: 0.72, blue: 0.95)
        case .oled:
            return Color(red: 0.75, green: 0.75, blue: 0.75)
        }
    }

    // MARK: - Canvas & Root Backgrounds
    public var backgroundColor: Color {
        switch self {
        case .paper:
            return Color(red: 0.96, green: 0.93, blue: 0.86)
        case .modern:
            return Color(red: 0.95, green: 0.96, blue: 0.98)
        case .dark:
            return BayanTheme.obsidian
        case .emerald:
            return Color(red: 0.02, green: 0.12, blue: 0.09)
        case .midnight:
            return Color(red: 0.03, green: 0.06, blue: 0.14)
        case .oled:
            return Color.black
        }
    }

    public var backgroundGradient: RadialGradient {
        switch self {
        case .paper:
            return RadialGradient(
                colors: [Color(red: 0.99, green: 0.96, blue: 0.90), Color(red: 0.94, green: 0.90, blue: 0.82)],
                center: .top,
                startRadius: 40,
                endRadius: 500
            )
        case .modern:
            return RadialGradient(
                colors: [Color.white, Color(red: 0.93, green: 0.95, blue: 0.98)],
                center: .top,
                startRadius: 40,
                endRadius: 500
            )
        case .dark:
            return RadialGradient(
                colors: [BayanTheme.deepEmerald.opacity(0.35), BayanTheme.obsidian],
                center: .center,
                startRadius: 40,
                endRadius: 500
            )
        case .emerald:
            return RadialGradient(
                colors: [Color(red: 0.05, green: 0.28, blue: 0.20), Color(red: 0.02, green: 0.10, blue: 0.08)],
                center: .top,
                startRadius: 50,
                endRadius: 550
            )
        case .midnight:
            return RadialGradient(
                colors: [Color(red: 0.08, green: 0.16, blue: 0.32), Color(red: 0.02, green: 0.05, blue: 0.12)],
                center: .top,
                startRadius: 50,
                endRadius: 550
            )
        case .oled:
            return RadialGradient(
                colors: [Color(red: 0.08, green: 0.08, blue: 0.08), Color.black],
                center: .center,
                startRadius: 40,
                endRadius: 500
            )
        }
    }

    // MARK: - Card Surface Backgrounds
    public var cardBackground: Color {
        switch self {
        case .paper:
            return Color(red: 0.99, green: 0.98, blue: 0.94)
        case .modern:
            return Color.white
        case .dark:
            return Color.white.opacity(0.06)
        case .emerald:
            return Color(red: 0.04, green: 0.19, blue: 0.15)
        case .midnight:
            return Color(red: 0.07, green: 0.13, blue: 0.24)
        case .oled:
            return Color(red: 0.08, green: 0.08, blue: 0.08)
        }
    }

    public var cardBorder: Color {
        switch self {
        case .paper:
            return Color(red: 0.88, green: 0.82, blue: 0.72)
        case .modern:
            return Color(red: 0.88, green: 0.90, blue: 0.94)
        case .dark:
            return Color.white.opacity(0.12)
        case .emerald:
            return Color(red: 0.15, green: 0.45, blue: 0.32).opacity(0.5)
        case .midnight:
            return Color(red: 0.20, green: 0.35, blue: 0.60).opacity(0.4)
        case .oled:
            return Color.white.opacity(0.15)
        }
    }

    public var activeCardBorder: Color {
        switch self {
        case .paper:
            return Color(red: 0.76, green: 0.58, blue: 0.22)
        case .modern:
            return Color(red: 0.18, green: 0.58, blue: 0.40)
        case .dark:
            return BayanTheme.gold
        case .emerald:
            return Color(red: 0.25, green: 0.90, blue: 0.60)
        case .midnight:
            return Color(red: 0.92, green: 0.76, blue: 0.35)
        case .oled:
            return Color(red: 0.90, green: 0.85, blue: 0.70)
        }
    }

    public var activeCardFill: Color {
        switch self {
        case .paper:
            return Color(red: 0.96, green: 0.88, blue: 0.65).opacity(0.22)
        case .modern:
            return Color(red: 0.18, green: 0.58, blue: 0.40).opacity(0.08)
        case .dark:
            return BayanTheme.gold.opacity(0.10)
        case .emerald:
            return Color(red: 0.25, green: 0.90, blue: 0.60).opacity(0.12)
        case .midnight:
            return Color(red: 0.92, green: 0.76, blue: 0.35).opacity(0.12)
        case .oled:
            return Color.white.opacity(0.10)
        }
    }

    // MARK: - Dual Hero Cards Backgrounds
    public var heroCardBackground: Color {
        switch self {
        case .paper:
            return Color(red: 0.24, green: 0.18, blue: 0.12)
        case .modern:
            return Color(red: 0.08, green: 0.32, blue: 0.25)
        case .dark:
            return Color(red: 0.08, green: 0.12, blue: 0.18)
        case .emerald:
            return Color(red: 0.04, green: 0.22, blue: 0.16)
        case .midnight:
            return Color(red: 0.06, green: 0.13, blue: 0.25)
        case .oled:
            return Color(red: 0.10, green: 0.10, blue: 0.10)
        }
    }

    // MARK: - Prayer Dashboard Theming Tokens
    public var prayerCardBackground: Color {
        switch self {
        case .paper:
            return Color(red: 0.99, green: 0.98, blue: 0.94)
        case .modern:
            return Color.white
        case .dark:
            return Color(red: 0.09, green: 0.12, blue: 0.16)
        case .emerald:
            return Color(red: 0.03, green: 0.16, blue: 0.12)
        case .midnight:
            return Color(red: 0.06, green: 0.11, blue: 0.20)
        case .oled:
            return Color(red: 0.07, green: 0.07, blue: 0.07)
        }
    }

    public var prayerCardActiveBackground: Color {
        switch self {
        case .paper:
            return Color(red: 0.95, green: 0.90, blue: 0.80)
        case .modern:
            return Color(red: 0.90, green: 0.96, blue: 0.93)
        case .dark:
            return Color(red: 0.14, green: 0.18, blue: 0.24)
        case .emerald:
            return Color(red: 0.06, green: 0.25, blue: 0.19)
        case .midnight:
            return Color(red: 0.09, green: 0.17, blue: 0.30)
        case .oled:
            return Color(red: 0.13, green: 0.13, blue: 0.13)
        }
    }

    public var prayerCardBorder: Color {
        switch self {
        case .paper:
            return Color(red: 0.88, green: 0.82, blue: 0.72)
        case .modern:
            return Color(red: 0.88, green: 0.90, blue: 0.94)
        case .dark:
            return Color.white.opacity(0.10)
        case .emerald:
            return Color(red: 0.15, green: 0.45, blue: 0.32).opacity(0.4)
        case .midnight:
            return Color(red: 0.22, green: 0.38, blue: 0.65).opacity(0.4)
        case .oled:
            return Color.white.opacity(0.12)
        }
    }

    public var prayerActiveAccent: Color {
        switch self {
        case .paper:
            return Color(red: 0.80, green: 0.60, blue: 0.20)
        case .modern:
            return Color(red: 0.18, green: 0.68, blue: 0.45)
        case .dark:
            return BayanTheme.gold
        case .emerald:
            return Color(red: 0.18, green: 0.85, blue: 0.52)
        case .midnight:
            return Color(red: 0.95, green: 0.78, blue: 0.35)
        case .oled:
            return Color(red: 0.90, green: 0.85, blue: 0.70)
        }
    }

    public var prayerTextColor: Color {
        switch self {
        case .paper:
            return Color(red: 0.12, green: 0.08, blue: 0.04)
        case .modern:
            return Color(red: 0.10, green: 0.12, blue: 0.16)
        case .dark, .emerald, .midnight, .oled:
            return .white
        }
    }

    public var prayerSecondaryTextColor: Color {
        switch self {
        case .paper:
            return Color(red: 0.48, green: 0.40, blue: 0.30)
        case .modern:
            return Color(red: 0.42, green: 0.46, blue: 0.54)
        case .dark:
            return .white.opacity(0.70)
        case .emerald:
            return Color(red: 0.70, green: 0.88, blue: 0.80)
        case .midnight:
            return Color(red: 0.65, green: 0.78, blue: 0.94)
        case .oled:
            return Color.white.opacity(0.70)
        }
    }

    public var prayerGaugeGradient: [Color] {
        switch self {
        case .paper:
            return [Color(red: 0.88, green: 0.70, blue: 0.30), Color(red: 0.75, green: 0.55, blue: 0.18)]
        case .modern:
            return [Color(red: 0.18, green: 0.78, blue: 0.48), Color(red: 0.10, green: 0.62, blue: 0.38)]
        case .dark:
            return [BayanTheme.gold, BayanTheme.goldSoft]
        case .emerald:
            return [Color(red: 0.20, green: 0.88, blue: 0.52), Color(red: 0.10, green: 0.70, blue: 0.40)]
        case .midnight:
            return [Color(red: 0.96, green: 0.82, blue: 0.38), Color(red: 0.88, green: 0.68, blue: 0.22)]
        case .oled:
            return [Color(red: 0.95, green: 0.90, blue: 0.75), Color(red: 0.80, green: 0.75, blue: 0.60)]
        }
    }

    // MARK: - Typography & Verse Text
    public var arabicTextColor: Color {
        switch self {
        case .paper:
            return Color(red: 0.13, green: 0.08, blue: 0.04)
        case .modern:
            return Color(red: 0.08, green: 0.10, blue: 0.14)
        case .dark, .emerald, .midnight, .oled:
            return .white
        }
    }

    public var activeArabicTextColor: Color {
        switch self {
        case .paper:
            return Color(red: 0.65, green: 0.45, blue: 0.12)
        case .modern:
            return Color(red: 0.10, green: 0.50, blue: 0.35)
        case .dark:
            return BayanTheme.goldSoft
        case .emerald:
            return Color(red: 0.35, green: 0.92, blue: 0.65)
        case .midnight:
            return Color(red: 0.96, green: 0.84, blue: 0.45)
        case .oled:
            return Color(red: 0.95, green: 0.90, blue: 0.75)
        }
    }

    public var translationTextColor: Color {
        switch self {
        case .paper:
            return Color(red: 0.42, green: 0.33, blue: 0.25)
        case .modern:
            return Color(red: 0.32, green: 0.36, blue: 0.44)
        case .dark:
            return .white.opacity(0.75)
        case .emerald:
            return Color(red: 0.80, green: 0.92, blue: 0.85)
        case .midnight:
            return Color(red: 0.80, green: 0.88, blue: 0.96)
        case .oled:
            return Color.white.opacity(0.80)
        }
    }

    public var headerTitleColor: Color {
        switch self {
        case .paper:
            return Color(red: 0.15, green: 0.09, blue: 0.04)
        case .modern:
            return Color(red: 0.08, green: 0.10, blue: 0.14)
        case .dark, .emerald, .midnight, .oled:
            return .white
        }
    }

    public var headerSubtitleColor: Color {
        switch self {
        case .paper:
            return Color(red: 0.62, green: 0.46, blue: 0.18)
        case .modern:
            return Color(red: 0.12, green: 0.52, blue: 0.42)
        case .dark:
            return BayanTheme.goldSoft
        case .emerald:
            return Color(red: 0.35, green: 0.90, blue: 0.65)
        case .midnight:
            return Color(red: 0.94, green: 0.80, blue: 0.42)
        case .oled:
            return Color(red: 0.90, green: 0.85, blue: 0.70)
        }
    }

    public var headerInfoColor: Color {
        switch self {
        case .paper:
            return Color(red: 0.48, green: 0.40, blue: 0.32)
        case .modern:
            return Color(red: 0.45, green: 0.48, blue: 0.55)
        case .dark:
            return .white.opacity(0.70)
        case .emerald:
            return Color(red: 0.70, green: 0.86, blue: 0.78)
        case .midnight:
            return Color(red: 0.70, green: 0.82, blue: 0.94)
        case .oled:
            return Color.white.opacity(0.65)
        }
    }

    public var bismillahColor: Color {
        switch self {
        case .paper:
            return Color(red: 0.58, green: 0.42, blue: 0.15)
        case .modern:
            return Color(red: 0.12, green: 0.52, blue: 0.42)
        case .dark:
            return BayanTheme.goldSoft
        case .emerald:
            return Color(red: 0.35, green: 0.90, blue: 0.65)
        case .midnight:
            return Color(red: 0.94, green: 0.80, blue: 0.42)
        case .oled:
            return Color(red: 0.90, green: 0.85, blue: 0.70)
        }
    }

    public var medallionBorder: Color {
        switch self {
        case .paper:
            return Color(red: 0.72, green: 0.56, blue: 0.24).opacity(0.6)
        case .modern:
            return Color(red: 0.12, green: 0.52, blue: 0.42).opacity(0.5)
        case .dark:
            return BayanTheme.gold.opacity(0.4)
        case .emerald:
            return Color(red: 0.35, green: 0.90, blue: 0.65).opacity(0.5)
        case .midnight:
            return Color(red: 0.94, green: 0.80, blue: 0.42).opacity(0.5)
        case .oled:
            return Color.white.opacity(0.35)
        }
    }

    public var medallionText: Color {
        switch self {
        case .paper:
            return Color(red: 0.62, green: 0.46, blue: 0.18)
        case .modern:
            return Color(red: 0.12, green: 0.52, blue: 0.42)
        case .dark:
            return BayanTheme.goldSoft
        case .emerald:
            return Color(red: 0.35, green: 0.90, blue: 0.65)
        case .midnight:
            return Color(red: 0.94, green: 0.80, blue: 0.42)
        case .oled:
            return Color(red: 0.90, green: 0.85, blue: 0.70)
        }
    }

    public var toolbarAccentColor: Color {
        switch self {
        case .paper:
            return Color(red: 0.62, green: 0.46, blue: 0.18)
        case .modern:
            return Color(red: 0.12, green: 0.52, blue: 0.42)
        case .dark:
            return BayanTheme.gold
        case .emerald:
            return Color(red: 0.30, green: 0.88, blue: 0.60)
        case .midnight:
            return Color(red: 0.94, green: 0.80, blue: 0.42)
        case .oled:
            return Color(red: 0.90, green: 0.85, blue: 0.70)
        }
    }

    public var toolbarItemColor: Color {
        switch self {
        case .paper:
            return Color(red: 0.35, green: 0.28, blue: 0.22)
        case .modern:
            return Color(red: 0.25, green: 0.28, blue: 0.35)
        case .dark, .emerald, .midnight, .oled:
            return .white.opacity(0.75)
        }
    }

    public var isDark: Bool {
        switch self {
        case .paper, .modern:
            return false
        case .dark, .emerald, .midnight, .oled:
            return true
        }
    }
}

// MARK: - Centralized App Theme Manager
/// Singleton managing global theme synchronization across all tabs and views.
@Observable
public final class AppThemeManager {
    public static let shared = AppThemeManager()

    public var currentTheme: QuranTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "bayan_app_theme")
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "bayan_quran_theme")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "bayan_app_theme")
            ?? UserDefaults.standard.string(forKey: "bayan_quran_theme")
            ?? QuranTheme.paper.rawValue
        self.currentTheme = QuranTheme(rawValue: saved) ?? .paper
    }

    public func setTheme(_ theme: QuranTheme) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.currentTheme = theme
        }
    }
}
