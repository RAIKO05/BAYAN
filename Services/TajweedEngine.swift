import SwiftUI

public final class TajweedEngine: @unchecked Sendable {
    public static let shared = TajweedEngine()

    // Precompiled Static Regexes to avoid costly recompilation on every redraw
    private static let maddRegex = try? NSRegularExpression(pattern: "[\\u0627\\u0648\\u064A\\u0670\\u06E5\\u06E6][\\u0653]", options: [])
    private static let standaloneMaddRegex = try? NSRegularExpression(pattern: "[\\u0653]", options: [])
    private static let ghunnahRegex = try? NSRegularExpression(pattern: "[\\u0646\\u0645][\\u0651][\\u064E\\u064F\\u0650]?", options: [])
    private static let qalqalahRegex = try? NSRegularExpression(pattern: "[\\u0642\\u0637\\u0628\\u062C\\u062F][\\u0652]", options: [])
    private static let iqlabRegex = try? NSRegularExpression(pattern: "[\\u06E2]", options: [])
    private static let idghamRegex = try? NSRegularExpression(pattern: "[\\u064B\\u064C\\u064D\\u0646\\u06DF]\\s*[\\u064A\\u0631\\u0645\\u0644\\u0648\\u0646][\\u0651]?", options: [])

    // High-performance thread-safe AttributedString cache for 120Hz scrolling
    private let cache = NSCache<NSString, CachedAttributedText>()

    private final class CachedAttributedText {
        let value: AttributedString
        init(_ value: AttributedString) { self.value = value }
    }

    private init() {
        cache.countLimit = 1000 // Cache up to 1,000 verses in memory (~2MB)
    }

    /// Colorizes Arabic Quranic text with standard Tajweed rules using fast cached evaluation.
    public func colorize(arabicText: String) -> AttributedString {
        let key = arabicText as NSString
        if let cached = cache.object(forKey: key) {
            return cached.value
        }

        var attributed = AttributedString(arabicText)

        // 1. Madd (~ / \u{0653} Maddah above) -> Red
        applyCompiledRegex(Self.maddRegex, to: &attributed, text: arabicText, color: TajweedRule.madd.color)
        applyCompiledRegex(Self.standaloneMaddRegex, to: &attributed, text: arabicText, color: TajweedRule.madd.color)

        // 2. Ghunnah (نّ / مّ - Noon/Meem with Shaddah) -> Amber
        applyCompiledRegex(Self.ghunnahRegex, to: &attributed, text: arabicText, color: TajweedRule.ghunnah.color)

        // 3. Qalqalah (ق، ط، ب، ج، د with Sukun) -> Emerald Teal
        applyCompiledRegex(Self.qalqalahRegex, to: &attributed, text: arabicText, color: TajweedRule.qalqalah.color)

        // 4. Iqlab (Small high meem \u{06E2}) -> Gold Yellow
        applyCompiledRegex(Self.iqlabRegex, to: &attributed, text: arabicText, color: TajweedRule.iqlab.color)

        // 5. Idgham (Letters of يرملون after tanween/noon) -> Purple
        applyCompiledRegex(Self.idghamRegex, to: &attributed, text: arabicText, color: TajweedRule.idgham.color)

        cache.setObject(CachedAttributedText(attributed), forKey: key)
        return attributed
    }

    private func applyCompiledRegex(
        _ regex: NSRegularExpression?,
        to attributed: inout AttributedString,
        text: String,
        color: Color
    ) {
        guard let regex = regex else { return }
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            if let range = Range(match.range, in: text),
               let lower = AttributedString.Index(range.lowerBound, within: attributed),
               let upper = AttributedString.Index(range.upperBound, within: attributed) {
                attributed[lower..<upper].foregroundColor = color
            }
        }
    }
}
