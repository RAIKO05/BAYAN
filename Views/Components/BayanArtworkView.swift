import SwiftUI

// MARK: - Official Bayan Sacred Artwork View
/// Exact digital replica of the Lock Screen & System Media Player Artwork:
/// 1. Deep luxury midnight obsidian/navy canvas gradient.
/// 2. Double beveled gold border with an inner inset hairline.
/// 3. Regal "BAYAN" serif gold typography.
/// 4. "The Holy Qur'an" subtitle in crisp ivory.
/// 5. Current Surah Arabic title in gleaming gold calligraphy.
public struct BayanArtworkView: View {
    public let surah: Surah
    public var size: CGFloat = 285
    public var cornerRadius: CGFloat = 26

    public init(surah: Surah, size: CGFloat = 285, cornerRadius: CGFloat = 26) {
        self.surah = surah
        self.size = size
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        ZStack {
            // 1. Deep Midnight Obsidian Canvas
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.05, green: 0.08, blue: 0.16),
                            Color(red: 0.02, green: 0.03, blue: 0.08)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: Color.black.opacity(0.65), radius: size > 100 ? 24 : 6, y: size > 100 ? 12 : 3)

            // 2. Outer Gold Beveled Border
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    Color(red: 0.95, green: 0.78, blue: 0.35).opacity(0.38),
                    lineWidth: size > 100 ? 2.5 : 1
                )
                .frame(width: size, height: size)

            // 3. Inner Inset Hairline Border
            RoundedRectangle(cornerRadius: max(6, cornerRadius - 7), style: .continuous)
                .stroke(
                    Color(red: 0.95, green: 0.78, blue: 0.35).opacity(0.18),
                    lineWidth: 1
                )
                .padding(size > 100 ? 9 : 3)
                .frame(width: size, height: size)

            // 4. Artwork Typography & Content
            if size > 120 {
                VStack(spacing: 6) {
                    Text("BAYAN")
                        .font(.system(size: size * 0.135, weight: .bold))
                        .foregroundColor(Color(red: 0.95, green: 0.78, blue: 0.35))
                        .tracking(size * 0.015)
                        .shadow(color: BayanTheme.gold.opacity(0.4), radius: 8)

                    Text("The Holy Qur'an")
                        .font(.system(size: size * 0.065, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .tracking(1.0)
                        .padding(.top, 2)

                    Text(surah.nameArabic)
                        .font(.system(size: size * 0.08, weight: .regular))
                        .foregroundColor(Color(red: 0.95, green: 0.78, blue: 0.35).opacity(0.85))
                        .padding(.top, size * 0.04)
                }
            } else {
                // Miniature Mode for Mini-Player & Small Badges
                VStack(spacing: 2) {
                    Text("BAYAN")
                        .font(.system(size: max(8, size * 0.22), weight: .black, design: .serif))
                        .foregroundColor(Color(red: 0.95, green: 0.78, blue: 0.35))
                    Text(surah.nameArabic)
                        .font(.system(size: max(8, size * 0.20), weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                }
            }
        }
    }
}
