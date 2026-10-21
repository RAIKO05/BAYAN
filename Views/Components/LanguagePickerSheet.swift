import SwiftUI

// MARK: - Language Picker Sheet
public struct LanguagePickerSheet: View {
    @State private var languageManager = AppLanguageManager.shared
    @State private var themeManager = AppThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    private var currentTheme: QuranTheme {
        themeManager.currentTheme
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                currentTheme.backgroundColor.ignoresSafeArea()
                currentTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Header Info Banner
                        HStack(spacing: 14) {
                            Image(systemName: "globe")
                                .font(.system(size: 24))
                                .foregroundColor(BayanTheme.gold)

                            VStack(alignment: .leading, spacing: 3) {
                                Text("app_language".localized)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Select your preferred language. The entire app layout will adapt automatically.")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.65))
                            }
                        }
                        .padding(16)
                        .liquidGlass(cornerRadius: 18)
                        .padding(.top, 8)

                        // Language Selection List
                        VStack(spacing: 12) {
                            ForEach(AppLanguage.allCases) { lang in
                                let isSelected = languageManager.currentLanguage == lang
                                Button {
                                    languageManager.setLanguage(lang)
                                } label: {
                                    HStack(spacing: 16) {
                                        Text(lang.flagEmoji)
                                            .font(.system(size: 32))

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(lang.displayName)
                                                .font(.headline.weight(.bold))
                                                .foregroundColor(isSelected ? BayanTheme.goldSoft : .white)

                                            Text(lang.subtitle)
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.6))
                                        }

                                        Spacer()

                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(BayanTheme.gold)
                                        }
                                    }
                                    .padding(18)
                                    .liquidGlass(cornerRadius: 18, isGoldBorder: isSelected)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Right to Left / Left to Right Note
                        HStack(spacing: 8) {
                            Image(systemName: "text.alignleft")
                                .font(.caption)
                                .foregroundColor(BayanTheme.goldSoft)
                            Text("Arabic utilizes native Right-To-Left (RTL) typography for an authentic Quranic reading experience.")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.55))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("app_language".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done".localized) {
                        dismiss()
                    }
                    .foregroundColor(BayanTheme.gold)
                    .font(.body.weight(.semibold))
                }
            }
        }
    }
}
