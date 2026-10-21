import SwiftUI

// MARK: - Quran Reading Theme Options (Modern, Paper, Dark)
public enum QuranTheme: String, CaseIterable, Identifiable, Codable {
    case modern = "Modern"
    case paper = "Paper"
    case dark = "Dark"

    public var id: String { rawValue }
    public var title: String { rawValue }

    // MARK: - Preview Box Appearance (Identical to reference screenshot)
    public var previewBackground: Color {
        switch self {
        case .modern:
            return Color(red: 0.93, green: 0.94, blue: 0.96)
        case .paper:
            return Color(red: 0.99, green: 0.96, blue: 0.88)
        case .dark:
            return Color(red: 0.14, green: 0.14, blue: 0.15)
        }
    }

    public var previewTextColor: Color {
        switch self {
        case .modern:
            return Color(red: 0.10, green: 0.12, blue: 0.16)
        case .paper:
            return Color(red: 0.15, green: 0.10, blue: 0.05)
        case .dark:
            return .white
        }
    }

    public var previewLabelColor: Color {
        switch self {
        case .modern:
            return Color(red: 0.20, green: 0.22, blue: 0.26)
        case .paper:
            return Color(red: 0.22, green: 0.16, blue: 0.10)
        case .dark:
            return Color(red: 0.85, green: 0.85, blue: 0.87)
        }
    }

    // MARK: - Full Quran Reader View Canvas
    public var backgroundColor: Color {
        switch self {
        case .modern:
            return Color(red: 0.95, green: 0.96, blue: 0.98)
        case .paper:
            return Color(red: 0.96, green: 0.93, blue: 0.86)
        case .dark:
            return BayanTheme.obsidian
        }
    }

    public var cardBackground: Color {
        switch self {
        case .modern:
            return Color.white
        case .paper:
            return Color(red: 0.99, green: 0.98, blue: 0.94)
        case .dark:
            return Color.white.opacity(0.05)
        }
    }

    public var cardBorder: Color {
        switch self {
        case .modern:
            return Color(red: 0.88, green: 0.90, blue: 0.94)
        case .paper:
            return Color(red: 0.88, green: 0.83, blue: 0.73)
        case .dark:
            return Color.white.opacity(0.12)
        }
    }

    public var activeCardBorder: Color {
        switch self {
        case .modern:
            return Color(red: 0.18, green: 0.58, blue: 0.40)
        case .paper:
            return Color(red: 0.76, green: 0.58, blue: 0.22)
        case .dark:
            return BayanTheme.gold
        }
    }

    public var activeCardFill: Color {
        switch self {
        case .modern:
            return Color(red: 0.18, green: 0.58, blue: 0.40).opacity(0.08)
        case .paper:
            return Color(red: 0.96, green: 0.88, blue: 0.65).opacity(0.22)
        case .dark:
            return BayanTheme.gold.opacity(0.10)
        }
    }

    // MARK: - Typography & Verse Text
    public var arabicTextColor: Color {
        switch self {
        case .modern:
            return Color(red: 0.08, green: 0.10, blue: 0.14)
        case .paper:
            return Color(red: 0.13, green: 0.08, blue: 0.04)
        case .dark:
            return .white
        }
    }

    public var activeArabicTextColor: Color {
        switch self {
        case .modern:
            return Color(red: 0.10, green: 0.50, blue: 0.35)
        case .paper:
            return Color(red: 0.65, green: 0.45, blue: 0.12)
        case .dark:
            return BayanTheme.goldSoft
        }
    }

    public var translationTextColor: Color {
        switch self {
        case .modern:
            return Color(red: 0.32, green: 0.36, blue: 0.44)
        case .paper:
            return Color(red: 0.42, green: 0.33, blue: 0.25)
        case .dark:
            return .white.opacity(0.75)
        }
    }

    public var headerTitleColor: Color {
        switch self {
        case .modern:
            return Color(red: 0.08, green: 0.10, blue: 0.14)
        case .paper:
            return Color(red: 0.15, green: 0.09, blue: 0.04)
        case .dark:
            return .white
        }
    }

    public var headerSubtitleColor: Color {
        switch self {
        case .modern:
            return Color(red: 0.12, green: 0.52, blue: 0.42)
        case .paper:
            return Color(red: 0.62, green: 0.46, blue: 0.18)
        case .dark:
            return BayanTheme.goldSoft
        }
    }

    public var headerInfoColor: Color {
        switch self {
        case .modern:
            return Color(red: 0.45, green: 0.48, blue: 0.55)
        case .paper:
            return Color(red: 0.48, green: 0.40, blue: 0.32)
        case .dark:
            return .white.opacity(0.70)
        }
    }

    public var bismillahColor: Color {
        switch self {
        case .modern:
            return Color(red: 0.12, green: 0.52, blue: 0.42)
        case .paper:
            return Color(red: 0.58, green: 0.42, blue: 0.15)
        case .dark:
            return BayanTheme.goldSoft
        }
    }

    public var medallionBorder: Color {
        switch self {
        case .modern:
            return Color(red: 0.12, green: 0.52, blue: 0.42).opacity(0.5)
        case .paper:
            return Color(red: 0.72, green: 0.56, blue: 0.24).opacity(0.6)
        case .dark:
            return BayanTheme.gold.opacity(0.4)
        }
    }

    public var medallionText: Color {
        switch self {
        case .modern:
            return Color(red: 0.12, green: 0.52, blue: 0.42)
        case .paper:
            return Color(red: 0.62, green: 0.46, blue: 0.18)
        case .dark:
            return BayanTheme.goldSoft
        }
    }

    public var toolbarAccentColor: Color {
        switch self {
        case .modern:
            return Color(red: 0.12, green: 0.52, blue: 0.42)
        case .paper:
            return Color(red: 0.62, green: 0.46, blue: 0.18)
        case .dark:
            return BayanTheme.gold
        }
    }

    public var toolbarItemColor: Color {
        switch self {
        case .modern:
            return Color(red: 0.25, green: 0.28, blue: 0.35)
        case .paper:
            return Color(red: 0.35, green: 0.28, blue: 0.22)
        case .dark:
            return .white.opacity(0.75)
        }
    }

    public var isDark: Bool {
        self == .dark
    }
}
