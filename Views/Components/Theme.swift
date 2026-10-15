import SwiftUI

// MARK: - Bayan Color Palette & Design Tokens
enum BayanTheme {
    // Primary Backgrounds
    static let obsidian = Color(red: 0.04, green: 0.05, blue: 0.07)
    static let deepEmerald = Color(red: 0.03, green: 0.20, blue: 0.16)
    static let emeraldGlow = Color(red: 0.08, green: 0.45, blue: 0.35)

    // Accents
    static let gold = Color(red: 0.90, green: 0.74, blue: 0.38)
    static let goldSoft = Color(red: 0.96, green: 0.88, blue: 0.65)
    static let electricCyan = Color(red: 0.20, green: 0.82, blue: 0.88)

    // Glass Colors
    static let glassStroke = LinearGradient(
        colors: [
            Color.white.opacity(0.35),
            Color.white.opacity(0.08),
            Color.white.opacity(0.02)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassGoldStroke = LinearGradient(
        colors: [
            gold.opacity(0.55),
            gold.opacity(0.15),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Liquid Glass Modifier
struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 24
    var isGoldBorder: Bool = false
    var opacity: CGFloat = 0.85

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(isGoldBorder ? BayanTheme.glassGoldStroke : BayanTheme.glassStroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 15, x: 0, y: 10)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 24, isGoldBorder: Bool = false) -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: cornerRadius, isGoldBorder: isGoldBorder))
    }
}
