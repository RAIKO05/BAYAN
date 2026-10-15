import SwiftUI

struct ResumeReadingCard: View {
    let surah: Surah
    let ayahNumber: Int
    let page: Int
    var onResume: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Icon Badge
            ZStack {
                Circle()
                    .fill(BayanTheme.gold.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: "bookmark.fill")
                    .font(.title3)
                    .foregroundColor(BayanTheme.gold)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(BayanTheme.electricCyan)
                        .frame(width: 6, height: 6)
                    Text("WHERE YOU STOPPED")
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundColor(BayanTheme.electricCyan)
                }

                Text("\(surah.nameEnglish) (\(surah.nameArabic))")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)

                Text("Ayah \(ayahNumber) • Page \(page)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Button(action: onResume) {
                HStack(spacing: 6) {
                    Text("Continue")
                        .font(.caption.weight(.bold))
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                }
                .foregroundColor(BayanTheme.obsidian)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [BayanTheme.gold, BayanTheme.goldSoft],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: BayanTheme.gold.opacity(0.3), radius: 6, y: 3)
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 22, isGoldBorder: true)
    }
}
