import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

// MARK: - Bayan Live Activity & Lock Screen Lyrics Settings View
/// Pixel-perfect implementation matching the user's settings screenshot:
/// 1. Navigation header "Live Activity" with back dismiss.
/// 2. Clean rounded grouped card:
///    - Toggle: "Live Activity" / "On the lock screen and in the Dynamic Island"
///    - Row: "Shows" -> "Lyrics" / "Lyrics & Translation" / "Translation Only"
/// 3. Visual preview simulator of the Lock Screen Quran Lyrics card.
/// 4. Direct 1-tap "Test on Lock Screen Now" button.
public struct BayanLiveActivitySettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("bayan_live_activity_enabled") private var isLiveActivityEnabled: Bool = true
    @AppStorage("bayan_live_activity_mode") private var liveActivityMode: String = "lyrics"

    @State private var showingModePickerSheet = false
    @State private var showingTestConfirmation = false

    private let spotifyGreen = Color(red: 0.18, green: 0.85, blue: 0.50)
    private let goldAccent = Color(red: 0.95, green: 0.78, blue: 0.35)

    public init() {}

    private var modeTitle: String {
        switch liveActivityMode {
        case "lyricsAndTranslation":
            return "Lyrics & Translation"
        case "translationOnly":
            return "Translation Only"
        default:
            return "Lyrics"
        }
    }

    public var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.06, blue: 0.08).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - 1. Main Settings Card (Exact Replica of Screenshot)
                    VStack(spacing: 0) {
                        // Toggle Row: Live Activity
                        HStack(alignment: .center, spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Live Activity")
                                    .font(.system(size: 16.5, weight: .semibold))
                                    .foregroundColor(.white)

                                Text("On the lock screen and in the Dynamic Island")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.white.opacity(0.55))
                            }

                            Spacer()

                            Toggle("", isOn: $isLiveActivityEnabled)
                                .labelsHidden()
                                .tint(spotifyGreen)
                                .onChange(of: isLiveActivityEnabled) { _, enabled in
                                    #if os(iOS)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    #endif
                                    #if canImport(ActivityKit)
                                    if !enabled {
                                        QuranLyricsLiveActivityManager.shared.endActivity()
                                    }
                                    #endif
                                }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)

                        Divider()
                            .background(Color.white.opacity(0.12))
                            .padding(.leading, 18)

                        // Selector Row: Shows
                        Button {
                            showingModePickerSheet = true
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        } label: {
                            HStack {
                                Text("Shows")
                                    .font(.system(size: 16.5, weight: .medium))
                                    .foregroundColor(.white)

                                Spacer()

                                HStack(spacing: 6) {
                                    Text(modeTitle)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(.white.opacity(0.65))

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.35))
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!isLiveActivityEnabled)
                        .opacity(isLiveActivityEnabled ? 1.0 : 0.45)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(red: 0.12, green: 0.13, blue: 0.16).opacity(0.95))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                    )

                    // MARK: - 2. Lock Screen Live Preview Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("LOCK SCREEN PREVIEW")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.45))
                            .padding(.horizontal, 4)

                        VStack(spacing: 10) {
                            // Header badge
                            HStack(spacing: 6) {
                                Image(systemName: "book.pages.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(goldAccent)

                                Text("Surah At-Tawbah")
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundColor(.white.opacity(0.85))

                                Text("•")
                                    .foregroundColor(.white.opacity(0.3))

                                Text("Ayah 40")
                                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                    .foregroundColor(goldAccent)

                                Spacer()

                                HStack(spacing: 5) {
                                    ReciterAvatarView(
                                        reciter: Reciter.standardCatalog.first(where: { $0.id == "maher" }) ?? Reciter.standardCatalog[0],
                                        size: 14,
                                        showBorder: false
                                    )
                                    Text("Maher Al-Muaiqly")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white.opacity(0.65))
                                }
                            }

                            // Ayah Arabic Text
                            if liveActivityMode == "translationOnly" {
                                Text("If you do not aid him, Allah has already aided him when those who disbelieved had driven him out as one of two, when they were in the cave...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text("إِلَّا تَنصُرُوهُ فَقَدْ نَصَرَهُ اللَّهُ إِذْ أَخْرَجَهُ الَّذِينَ كَفَرُوا ثَانِيَ اثْنَيْنِ إِذْ هُمَا فِي الْغَارِ ﴿٤٠﴾")
                                    .font(.system(size: 17, weight: .bold, design: .serif))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(6)
                                    .environment(\.layoutDirection, .rightToLeft)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }

                            // Subtitle Snippet
                            if liveActivityMode == "lyricsAndTranslation" {
                                Text("If you do not aid him, Allah has already aided him when those who disbelieved had driven him out...")
                                    .font(.system(size: 11.5, weight: .regular))
                                    .foregroundColor(goldAccent.opacity(0.85))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            } else if liveActivityMode == "lyrics" {
                                Text("إِذْ يَقُولُ لِصَاحِبِهِ لَا تَحْزَنْ إِنَّ اللَّهَ مَعَنَا فَأَنزَلَ اللَّهُ سَكِينَتَهُ...")
                                    .font(.system(size: 12.5, weight: .regular, design: .serif))
                                    .foregroundColor(.white.opacity(0.45))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(1)
                                    .environment(\.layoutDirection, .rightToLeft)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.98))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(goldAccent.opacity(0.22), lineWidth: 0.8)
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 16, y: 8)
                    }

                    // MARK: - 3. Test on Lock Screen Button
                    Button {
                        #if canImport(ActivityKit)
                        QuranLyricsLiveActivityManager.shared.testPreviewActivity()
                        #endif
                        showingTestConfirmation = true
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.display")
                                .font(.system(size: 15, weight: .bold))
                            Text(showingTestConfirmation ? "✅ Live Activity Sent to Lock Screen" : "Test Live Activity on Lock Screen")
                                .font(.system(size: 14.5, weight: .bold))
                        }
                        .foregroundColor(showingTestConfirmation ? spotifyGreen : .black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(showingTestConfirmation ? Color.white.opacity(0.08) : goldAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!isLiveActivityEnabled)

                    Text("When reciting Quran, the current Ayah text is displayed live on your Lock Screen and in the Dynamic Island, advancing synchronously with each verse.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .padding(18)
            }
        }
        .navigationTitle("Live Activity")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("What to Show", isPresented: $showingModePickerSheet, titleVisibility: .visible) {
            Button("Lyrics (Arabic Ayah Text)") {
                liveActivityMode = "lyrics"
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
            }
            Button("Lyrics & Translation") {
                liveActivityMode = "lyricsAndTranslation"
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
            }
            Button("Translation Only") {
                liveActivityMode = "translationOnly"
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose whether to display authentic Arabic verse calligraphy, English translation, or both on your Lock Screen.")
        }
    }
}
