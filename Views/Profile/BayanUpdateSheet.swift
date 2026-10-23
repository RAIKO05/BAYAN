import SwiftUI

// MARK: - Bayan Update Sheet
/// Modal presentation providing release notes, version comparison, and direct 1-tap IPA download.
public struct BayanUpdateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var updateService = BayanUpdateService.shared
    @State private var themeManager = AppThemeManager.shared

    private let spotifyGreen = Color(red: 0.18, green: 0.85, blue: 0.50)

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                themeManager.currentTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Hero Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [BayanTheme.gold.opacity(0.35), spotifyGreen.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 84, height: 84)
                                    .overlay(Circle().stroke(BayanTheme.gold, lineWidth: 2))

                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 42))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [BayanTheme.gold, spotifyGreen],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                            .padding(.top, 10)

                            Text(updateService.isUpdateAvailable ? "New Version Available!" : "You're Up to Date")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)

                            HStack(spacing: 8) {
                                Text("v\(updateService.latestVersion)")
                                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                                    .foregroundColor(BayanTheme.gold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(BayanTheme.gold.opacity(0.15))
                                    .clipShape(Capsule())

                                if updateService.latestBuild > 0 {
                                    Text("Build \(updateService.latestBuild)")
                                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                        .foregroundColor(spotifyGreen)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(spotifyGreen.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        // MARK: - Version Comparison Card
                        HStack(spacing: 0) {
                            VStack(spacing: 4) {
                                Text("CURRENT VERSION")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.45))
                                    .tracking(0.6)
                                Text("v\(updateService.currentVersion)")
                                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.85))
                                Text("Build \(updateService.currentBuild)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)

                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 1, height: 42)

                            VStack(spacing: 4) {
                                Text("LATEST RELEASE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(spotifyGreen)
                                    .tracking(0.6)
                                Text("v\(updateService.latestVersion.isEmpty ? updateService.currentVersion : updateService.latestVersion)")
                                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                                    .foregroundColor(BayanTheme.gold)
                                Text(updateService.latestBuild > 0 ? "Build \(updateService.latestBuild)" : "Latest")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(spotifyGreen.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )

                        // MARK: - Primary Action Buttons
                        VStack(spacing: 10) {
                            Button {
                                updateService.openDownload()
                                #if os(iOS)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                #endif
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.down.doc.fill")
                                    Text("Download Update (.ipa)")
                                }
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    LinearGradient(
                                        colors: [BayanTheme.gold, spotifyGreen],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .shadow(color: spotifyGreen.opacity(0.35), radius: 10, y: 4)
                            }

                            Button {
                                updateService.openReleasePage()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "safari.fill")
                                    Text("View Release on GitHub")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }

                        // MARK: - Release Notes
                        if !updateService.releaseNotes.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(BayanTheme.gold)
                                        .font(.system(size: 12))
                                    Text("WHAT'S NEW")
                                        .font(.system(size: 11, weight: .heavy))
                                        .foregroundColor(BayanTheme.goldSoft)
                                        .tracking(0.8)
                                }

                                Text(cleanReleaseNotes(updateService.releaseNotes))
                                    .font(.system(size: 12.5, weight: .regular))
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(red: 0.10, green: 0.11, blue: 0.14).opacity(0.92))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(BayanTheme.gold.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }

                        // MARK: - Sideloading Instructions Tip
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(BayanTheme.goldSoft)
                                    .font(.system(size: 12))
                                Text("HOW TO INSTALL")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(BayanTheme.goldSoft)
                            }

                            Text("Tap 'Download Update' to download the latest `.ipa`. Then open the file with TrollStore, AltStore, LiveContainer, or Sideloadly to update in place. Your bookmarks, reciter preferences, and Khatmah progress remain 100% safe.")
                                .font(.system(size: 11.5))
                                .foregroundColor(.white.opacity(0.6))
                                .lineSpacing(3)
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(16)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("App Update")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(BayanTheme.gold)
                    .font(.system(size: 14, weight: .bold))
                }
            }
        }
    }

    private func cleanReleaseNotes(_ notes: String) -> String {
        // Strip markdown headers like ### or ##
        let cleaned = notes
            .replacingOccurrences(of: "### ", with: "• ")
            .replacingOccurrences(of: "## ", with: "")
            .replacingOccurrences(of: "**", with: "")
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
