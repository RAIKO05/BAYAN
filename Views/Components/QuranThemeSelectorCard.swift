import SwiftUI

// MARK: - Quran Theme Selector Card (Matches Reference UI & Supports 6 Rich Themes)
public struct QuranThemeSelectorCard: View {
    @Binding var selectedTheme: QuranTheme
    var onThemeChanged: ((QuranTheme) -> Void)? = nil

    private let greenSelectedBorder = Color(red: 0.18, green: 0.58, blue: 0.40)
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    public init(selectedTheme: Binding<QuranTheme>, onThemeChanged: ((QuranTheme) -> Void)? = nil) {
        self._selectedTheme = selectedTheme
        self.onThemeChanged = onThemeChanged
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Themes & Appearance")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(selectedTheme.isDark ? .white : Color(red: 0.10, green: 0.12, blue: 0.16))

                Spacer()

                Text("App-Wide Unified")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(selectedTheme.toolbarAccentColor)
            }
            .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(QuranTheme.allCases) { theme in
                    let isSelected = selectedTheme == theme
                    Button {
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedTheme = theme
                        }
                        AppThemeManager.shared.setTheme(theme)
                        onThemeChanged?(theme)
                    } label: {
                        VStack(spacing: 6) {
                            // Arabic Calligraphy Sample
                            Text("بِسْمِ اللَّهِ")
                                .font(.system(size: 17, weight: .bold, design: .serif))
                                .foregroundColor(theme.previewTextColor)
                                .multilineTextAlignment(.center)
                                .frame(height: 30)

                            // Theme Name Label
                            Text(theme.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(theme.previewLabelColor)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 74)
                        .background(theme.previewBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(isSelected ? (theme.isDark ? BayanTheme.gold : greenSelectedBorder) : Color.black.opacity(0.08), lineWidth: isSelected ? 2.5 : 1)
                        )
                        .shadow(color: isSelected ? (theme.isDark ? BayanTheme.gold.opacity(0.3) : greenSelectedBorder.opacity(0.2)) : Color.black.opacity(0.04), radius: isSelected ? 6 : 2, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(
            selectedTheme.isDark
                ? Color(red: 0.11, green: 0.12, blue: 0.14)
                : Color.white
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(selectedTheme.isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(selectedTheme.isDark ? 0.35 : 0.08), radius: 16, x: 0, y: 6)
    }
}
