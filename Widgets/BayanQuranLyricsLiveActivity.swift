#if canImport(ActivityKit)
import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Bayan Quran Lyrics Live Activity Widget
/// Displays synchronized Quran verse text ("Lyrics") directly on the iOS Lock Screen
/// and in the Dynamic Island as recitation plays.
public struct BayanQuranLyricsLiveActivity: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: QuranLyricsActivityAttributes.self) { context in
            // MARK: - iOS Lock Screen Presentation
            LockScreenQuranLyricsView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.88))
                .activitySystemActionForegroundColor(Color(red: 0.95, green: 0.78, blue: 0.35))
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Dynamic Island Expanded
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 0.95, green: 0.78, blue: 0.35))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Surah \(context.state.surahNameEnglish)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text("Ayah \(context.state.ayahNumber) of \(context.state.totalAyahs)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.leading, 8)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.surahNameArabic)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 0.95, green: 0.78, blue: 0.35))
                        Text(context.state.reciterName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    .padding(.trailing, 8)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        // Current Arabic Verse Lyrics
                        Text(context.state.currentAyahArabic)
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .environment(\.layoutDirection, .rightToLeft)
                            .padding(.horizontal, 6)

                        // Secondary: Translation or Next Verse Snippet
                        if context.state.displayMode == "lyricsAndTranslation" && !context.state.translationText.isEmpty {
                            Text(context.state.translationText)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(Color(red: 0.95, green: 0.78, blue: 0.35).opacity(0.85))
                                .lineLimit(1)
                        } else if !context.state.nextAyahArabic.isEmpty {
                            Text(context.state.nextAyahArabic)
                                .font(.system(size: 11, weight: .regular, design: .serif))
                                .foregroundColor(.white.opacity(0.45))
                                .lineLimit(1)
                                .environment(\.layoutDirection, .rightToLeft)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)
                }
            } compactLeading: {
                // MARK: - Dynamic Island Compact Leading
                HStack(spacing: 3) {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(red: 0.95, green: 0.78, blue: 0.35))
                    Text("\(context.state.surahId):\(context.state.ayahNumber)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.leading, 4)
            } compactTrailing: {
                // MARK: - Dynamic Island Compact Trailing
                Text(context.state.surahNameArabic)
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(Color(red: 0.95, green: 0.78, blue: 0.35))
                    .padding(.trailing, 4)
            } minimal: {
                // MARK: - Dynamic Island Minimal
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.95, green: 0.78, blue: 0.35))
            }
        }
    }
}

// MARK: - Lock Screen Banner Presentation
/// Pixel-perfect recreation of the user's requested Lock Screen Quran Reading Card
private struct LockScreenQuranLyricsView: View {
    let state: QuranLyricsActivityAttributes.ContentState

    private let goldAccent = Color(red: 0.95, green: 0.78, blue: 0.35)

    var body: some View {
        VStack(spacing: 8) {
            // MARK: - 1. Subtle Header Strip (Surah • Ayah • Reciter)
            HStack(spacing: 6) {
                // Golden Quran Emblem
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(goldAccent)

                Text("Surah \(state.surahNameEnglish)")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))

                Text("•")
                    .foregroundColor(.white.opacity(0.3))

                Text("Ayah \(state.ayahNumber)")
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundColor(goldAccent)

                Spacer()

                // Reciter Indicator
                HStack(spacing: 4) {
                    Text("🗣️")
                        .font(.system(size: 10))
                    Text(state.reciterName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 4)

            // MARK: - 2. Primary Arabic Ayah Text ("Lyrics")
            // Prominent, high-contrast, beautiful Arabic typography
            if state.displayMode == "translationOnly" {
                Text(state.translationText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 2)
            } else {
                Text(state.currentAyahArabic)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(7)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .environment(\.layoutDirection, .rightToLeft)
                    .padding(.vertical, 2)
            }

            // MARK: - 3. Secondary Line: Next Verse Sneak Peek or English Translation
            if state.displayMode == "lyricsAndTranslation" && !state.translationText.isEmpty {
                Text(state.translationText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(goldAccent.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if state.displayMode == "lyrics" && !state.nextAyahArabic.isEmpty {
                Text(state.nextAyahArabic)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundColor(.white.opacity(0.48))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .environment(\.layoutDirection, .rightToLeft)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(goldAccent.opacity(0.18), lineWidth: 0.8)
        )
    }
}
#endif
