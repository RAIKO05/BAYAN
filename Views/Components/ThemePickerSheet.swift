import SwiftUI

public struct ThemePickerSheet: View {
    @State private var themeManager = AppThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                themeManager.currentTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        QuranThemeSelectorCard(selectedTheme: $themeManager.currentTheme)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("app_theme".localized)
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
