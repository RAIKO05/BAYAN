import SwiftUI

public final class TajweedEngine {
    public static let shared = TajweedEngine()

    private init() {}

    /// Colorizes Arabic Quranic text with standard Tajweed rules.
    public func colorize(arabicText: String) -> AttributedString {
        var attributed = AttributedString(arabicText)

        // 1. Madd (~ / \u{0653} Maddah above) -> Red
        let maddPattern = "[\\u0627\\u0648\\u064A\\u0670\\u06E5\\u06E6][\\u0653]"
        applyColor(to: &attributed, text: arabicText, regexPattern: maddPattern, color: TajweedRule.madd.color)

        // Also standalone maddah
        applyColor(to: &attributed, text: arabicText, regexPattern: "[\\u0653]", color: TajweedRule.madd.color)

        // 2. Ghunnah (نّ / مّ - Noon/Meem with Shaddah) -> Amber
        let ghunnahPattern = "[\\u0646\\u0645][\\u0651][\\u064E\\u064F\\u0650]?"
        applyColor(to: &attributed, text: arabicText, regexPattern: ghunnahPattern, color: TajweedRule.ghunnah.color)

        // 3. Qalqalah (ق، ط، ب، ج، د with Sukun or terminal) -> Emerald Teal
        let qalqalahPattern = "[\\u0642\\u0637\\u0628\\u062C\\u062F][\\u0652]"
        applyColor(to: &attributed, text: arabicText, regexPattern: qalqalahPattern, color: TajweedRule.qalqalah.color)

        // 4. Iqlab (Small high meem \u{06E2}) -> Gold Yellow
        let iqlabPattern = "[\\u06E2]"
        applyColor(to: &attributed, text: arabicText, regexPattern: iqlabPattern, color: TajweedRule.iqlab.color)

        // 5. Idgham (Letters of يرملون after tanween/noon) -> Purple
        let idghamPattern = "[\\u064B\\u064C\\u064D\\u0646\\u06DF]\\s*[\\u064A\\u0631\\u0645\\u0644\\u0648\\u0646][\\u0651]?"
        applyColor(to: &attributed, text: arabicText, regexPattern: idghamPattern, color: TajweedRule.idgham.color)

        return attributed
    }

    private func applyColor(
        to attributed: inout AttributedString,
        text: String,
        regexPattern: String,
        color: Color
    ) {
        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: []) else { return }
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            if let range = Range(match.range, in: text),
               let attrRange = Range(range, in: attributed) {
                attributed[attrRange].foregroundColor = color
            }
        }
    }
}
