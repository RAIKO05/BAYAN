import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Bayan Discord Rich Presence Settings View
/// Allows users to broadcast their active Quran recitation to their Discord profile
/// with live progress bar, Surah name in Arabic & English, reciter, and artwork.
/// Features 1-click seamless official Discord login (zero manual copy-pasting).
public struct BayanDiscordRPCSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var discordRPC = DiscordRPCService.shared
    @State private var playerService = AudioPlayerService.shared

    @State private var showingLoginSheet = false
    @State private var showingManualToken = false
    @State private var inputToken: String = ""
    @State private var isTokenVisible: Bool = false
    @State private var showingTokenHelpSheet = false
    @State private var customAppId: String = ""
    @State private var testPresenceSent = false

    // Discord Brand Colors
    private let discordBlurple = Color(red: 0.35, green: 0.40, blue: 0.95) // #5865F2
    private let discordDarkBg = Color(red: 0.17, green: 0.18, blue: 0.20)  // #2B2D31
    private let discordCardBg = Color(red: 0.12, green: 0.13, blue: 0.14)  // #1E1F22
    private let discordGreen = Color(red: 0.14, green: 0.73, blue: 0.41)   // #23A55A
    private let goldAccent = Color(red: 0.95, green: 0.78, blue: 0.35)

    public init() {}

    public var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.06, blue: 0.08).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - 1. Live Discord Profile Preview Card
                    discordProfilePreviewCard

                    // MARK: - 2. Master Toggle & Connection Status
                    masterToggleCard

                    // MARK: - 3. Seamless 1-Click Discord Account Card
                    accountConnectionCard

                    // MARK: - 4. Display Preferences Card
                    displayPreferencesCard

                    // MARK: - 5. Advanced Application ID Card
                    advancedAppIdCard
                }
                .padding(16)
                .padding(.bottom, 40)
                .frame(maxWidth: 720)
            }
        }
        .navigationTitle("Discord Rich Presence")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            inputToken = discordRPC.userToken
            customAppId = discordRPC.applicationId
        }
        .sheet(isPresented: $showingLoginSheet) {
            DiscordLoginSheet()
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showingTokenHelpSheet) {
            tokenHelpSheet
                .presentationDetents([.large])
        }
    }

    // MARK: - 1. Discord Profile Card Simulator
    private var discordProfilePreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DISCORD PROFILE PREVIEW")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(0.5)

                Spacer()

                if discordRPC.isConnected {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(discordGreen)
                            .frame(width: 7, height: 7)
                        Text("Live on Discord")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(discordGreen)
                    }
                }
            }

            // Real Discord Dark Profile Modal Component
            VStack(alignment: .leading, spacing: 12) {
                // Category Label
                Text("LISTENING TO HOLY QUR'AN")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(Color(red: 0.71, green: 0.73, blue: 0.76)) // #B5BAC1
                    .tracking(0.4)

                HStack(alignment: .top, spacing: 12) {
                    // Large Asset Image (Bayan Gold Monogram)
                    ZStack(alignment: .bottomTrailing) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.08, green: 0.28, blue: 0.20), Color(red: 0.03, green: 0.12, blue: 0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 68, height: 68)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(goldAccent.opacity(0.4), lineWidth: 1)
                            )
                            .overlay(
                                Text("بَيَان")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(goldAccent)
                            )

                        // Small Asset Badge (Play indicator)
                        Circle()
                            .fill(Color(red: 0.12, green: 0.13, blue: 0.14))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .fill(discordGreen)
                                    .frame(width: 20, height: 20)
                            )
                            .overlay(
                                Image(systemName: playerService.isPlaying ? "play.fill" : "pause.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 4, y: 4)
                    }

                    // Activity Details & Subtitle
                    VStack(alignment: .leading, spacing: 4) {
                        Text(activeSurahTitle)
                            .font(.system(size: 14.5, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(activeStateSubtitle)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(Color(red: 0.71, green: 0.73, blue: 0.76))
                            .lineLimit(1)

                        // Live Time Scrubber Timeline
                        if discordRPC.showTimeline {
                            VStack(spacing: 3) {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.white.opacity(0.15))
                                            .frame(height: 4)

                                        Capsule()
                                            .fill(discordBlurple)
                                            .frame(width: max(8, geo.size.width * timelineProgress), height: 4)
                                    }
                                }
                                .frame(height: 4)
                                .padding(.top, 2)

                                HStack {
                                    Text(formattedTime(playerService.currentTime))
                                    Spacer()
                                    Text(formattedTime(playerService.duration > 0 ? playerService.duration : 240))
                                }
                                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color(red: 0.60, green: 0.62, blue: 0.66))
                            }
                            .padding(.top, 2)
                        }
                    }
                }

                // Interactive Discord Button
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "headphones")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Listen on Bayan")
                            .font(.system(size: 12.5, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
            .padding(14)
            .background(discordDarkBg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(16)
        .background(Color(red: 0.10, green: 0.11, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - 2. Master Toggle & Connection Status
    private var masterToggleCard: some View {
        VStack(spacing: 0) {
            // Main Toggle
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(discordBlurple.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(discordBlurple)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Discord Rich Presence")
                        .font(.system(size: 15.5, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Broadcast active recitation to your Discord profile")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { discordRPC.isEnabled },
                    set: { enabled in
                        discordRPC.isEnabled = enabled
                        triggerHaptic()
                    }
                ))
                .labelsHidden()
                .tint(discordBlurple)
            }
            .padding(16)

            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.leading, 70)

            // Connection Status Row
            HStack(spacing: 12) {
                Circle()
                    .fill(discordRPC.connectionState.statusColor)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(discordRPC.connectionState.statusDescription)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(discordRPC.connectionState.statusColor == .red ? Color(red: 1.0, green: 0.4, blue: 0.4) : .white)
                        .lineLimit(2)

                    if !discordRPC.hasToken {
                        Text("Connect your Discord account below to start")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Spacer()

                if discordRPC.isConnected {
                    Button {
                        discordRPC.sendTestPresence()
                        testPresenceSent = true
                        triggerHaptic()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            testPresenceSent = false
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: testPresenceSent ? "checkmark" : "paperplane.fill")
                            Text(testPresenceSent ? "Sent!" : "Test")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(testPresenceSent ? discordGreen : discordBlurple)
                        .clipShape(Capsule())
                    }
                } else if discordRPC.hasToken && discordRPC.isEnabled {
                    Button("Reconnect") {
                        discordRPC.connect()
                        triggerHaptic()
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            .padding(16)
        }
        .background(Color(red: 0.10, green: 0.11, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - 3. Seamless 1-Click Discord Account Card
    private var accountConnectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("DISCORD ACCOUNT")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(0.5)

                Spacer()
            }

            if case .connected(let username, let disc, let avatarUrl, let isBot) = discordRPC.connectionState {
                VStack(spacing: 10) {
                    // Connected User Profile Row
                    HStack(spacing: 12) {
                        if let avatarUrl = avatarUrl, let url = URL(string: avatarUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable()
                                        .scaledToFill()
                                        .frame(width: 44, height: 44)
                                        .clipShape(Circle())
                                default:
                                    fallbackAvatar
                                }
                            }
                        } else {
                            fallbackAvatar
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(username)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)

                                if isBot {
                                    Text("BOT")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(discordBlurple)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                            }

                            Text(disc == "0" || disc.isEmpty ? "@\(username)" : "#\(disc)")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.55))
                        }

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(discordGreen)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    // Action Buttons: Switch Account & Disconnect
                    HStack(spacing: 10) {
                        Button {
                            discordRPC.removeToken()
                            inputToken = ""
                            triggerHaptic()
                            showingLoginSheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Switch Account")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(discordBlurple)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }

                        Button {
                            discordRPC.removeToken()
                            inputToken = ""
                            triggerHaptic()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Disconnect")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.red.opacity(0.9))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }

            } else {
                // Big 1-Click Connect Button
                Button {
                    showingLoginSheet = true
                    triggerHaptic()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Connect with Discord")
                            .font(.system(size: 14.5, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(discordBlurple)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: discordBlurple.opacity(0.35), radius: 8, y: 3)
                }

                Text("Sign in once with your Discord account. No manual token copy-pasting required.")
                    .font(.system(size: 11.5))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Advanced / Manual Token Expander
            DisclosureGroup(
                isExpanded: $showingManualToken,
                content: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("MANUAL / BOT TOKEN")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))

                            Spacer()

                            Button {
                                showingTokenHelpSheet = true
                                triggerHaptic()
                            } label: {
                                Text("Guide")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(goldAccent)
                            }
                        }
                        .padding(.top, 8)

                        HStack(spacing: 8) {
                            Group {
                                if isTokenVisible {
                                    TextField("Paste token...", text: $inputToken)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                } else {
                                    SecureField("Paste token...", text: $inputToken)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                }
                            }
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white)

                            Button {
                                isTokenVisible.toggle()
                            } label: {
                                Image(systemName: isTokenVisible ? "eye.slash.fill" : "eye.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.5))
                            }

                            #if canImport(UIKit)
                            Button {
                                if let string = UIPasteboard.general.string {
                                    inputToken = discordRPC.cleanToken(string)
                                    discordRPC.saveToken(inputToken)
                                    triggerHaptic()
                                }
                            } label: {
                                Text("Paste")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(goldAccent)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            #endif
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        Button {
                            discordRPC.saveToken(inputToken)
                            triggerHaptic()
                        } label: {
                            Text("Save Token")
                                .font(.system(size: 12.5, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                },
                label: {
                    Text("Advanced: Enter Token Manually")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            )
            .tint(Color.white.opacity(0.4))
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(red: 0.10, green: 0.11, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var fallbackAvatar: some View {
        Circle()
            .fill(discordBlurple)
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.white)
            )
    }

    // MARK: - 4. Display Preferences Card
    private var displayPreferencesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("DISPLAY PREFERENCES")
                .font(.system(size: 11.5, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .tracking(0.5)

            VStack(spacing: 12) {
                Toggle(isOn: Binding(
                    get: { discordRPC.showReciter },
                    set: { val in discordRPC.showReciter = val; triggerHaptic() }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show Reciter Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        Text("Display current Qari (e.g. Mishary Alafasy)")
                            .font(.system(size: 11.5))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .tint(discordBlurple)

                Divider().background(Color.white.opacity(0.08))

                Toggle(isOn: Binding(
                    get: { discordRPC.showAyahNumber },
                    set: { val in discordRPC.showAyahNumber = val; triggerHaptic() }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show Ayah Number")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        Text("Include current verse index (e.g. Ayah 10/110)")
                            .font(.system(size: 11.5))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .tint(discordBlurple)

                Divider().background(Color.white.opacity(0.08))

                Toggle(isOn: Binding(
                    get: { discordRPC.showTimeline },
                    set: { val in discordRPC.showTimeline = val; triggerHaptic() }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show Live Progress Bar")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        Text("Display elapsed / remaining recitation scrubber")
                            .font(.system(size: 11.5))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .tint(discordBlurple)

                Divider().background(Color.white.opacity(0.08))

                Toggle(isOn: Binding(
                    get: { discordRPC.clearWhenPaused },
                    set: { val in discordRPC.clearWhenPaused = val; triggerHaptic() }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clear Status When Paused")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        Text("If disabled, shows \"⏸ Paused\" instead of clearing")
                            .font(.system(size: 11.5))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .tint(discordBlurple)
            }
        }
        .padding(16)
        .background(Color(red: 0.10, green: 0.11, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - 5. Advanced Application ID Card
    private var advancedAppIdCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("DISCORD APPLICATION ID")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(0.5)

                Spacer()

                if discordRPC.applicationId == DiscordRPCService.defaultApplicationId {
                    Text("Bundled Default")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(goldAccent)
                } else {
                    Button("Reset") {
                        discordRPC.applicationId = DiscordRPCService.defaultApplicationId
                        customAppId = DiscordRPCService.defaultApplicationId
                        triggerHaptic()
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.orange)
                }
            }

            HStack {
                TextField("Application ID", text: $customAppId)
                    .font(.system(size: 12.5, design: .monospaced))
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Button("Apply") {
                    discordRPC.applicationId = customAppId.trimmingCharacters(in: .whitespacesAndNewlines)
                    triggerHaptic()
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.85))
                .clipShape(Capsule())
            }
            .padding(10)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("Pre-configured with Bayan's verified \"Holy Qur'an\" Application ID. You do not need to change this unless you want to use your own custom Discord Developer Application.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.45))
        }
        .padding(16)
        .background(Color(red: 0.10, green: 0.11, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Helpers & Formatters
    private var activeSurahTitle: String {
        if let surah = playerService.currentSurah {
            return "Surah \(surah.nameEnglish) (\(surah.nameArabic))"
        }
        return "Surah Al-Kahf (الكهف)"
    }

    private var activeStateSubtitle: String {
        let reciterName = playerService.currentReciter.nameEnglish
        let ayahNumber = playerService.currentSurah != nil ? playerService.currentAyah : 1
        let total = playerService.currentSurah?.totalAyahs ?? 110

        var parts: [String] = []
        if discordRPC.showReciter { parts.append(reciterName) }
        if discordRPC.showAyahNumber { parts.append("Ayah \(ayahNumber)/\(total)") }

        let state = parts.joined(separator: " • ")
        return playerService.isPlaying ? state : "⏸ Paused • \(state)"
    }

    private var timelineProgress: CGFloat {
        let duration = playerService.duration > 0 ? playerService.duration : 240
        let current = playerService.currentTime > 0 ? playerService.currentTime : 45
        return CGFloat(min(1.0, max(0.0, current / duration)))
    }

    private func formattedTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    // MARK: - Token Tutorial Modal Sheet
    private var tokenHelpSheet: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.09, blue: 0.11).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack(spacing: 12) {
                            Image(systemName: "key.horizontal.fill")
                                .font(.system(size: 26))
                                .foregroundColor(goldAccent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Getting your Discord Token")
                                    .font(.system(size: 19, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Follow either Method 1 or Method 2 below")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.top, 10)

                        // METHOD 1: NETWORK TAB (100% RELIABLE)
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("METHOD 1: NETWORK TAB (RECOMMENDED)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(discordGreen)
                                Spacer()
                                Text("100% Guaranteed")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(discordGreen)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(discordGreen.opacity(0.15))
                                    .clipShape(Capsule())
                            }

                            helpStepRow(
                                number: "1",
                                title: "Open Discord in Chrome / Safari / Edge",
                                text: "Go to discord.com/app on your PC, Mac, or phone browser and log in."
                            )

                            helpStepRow(
                                number: "2",
                                title: "Open Inspect (DevTools)",
                                text: "Press F12 or right-click anywhere on the page and select 'Inspect'."
                            )

                            helpStepRow(
                                number: "3",
                                title: "Click 'Network' Tab",
                                text: "Select the 'Network' tab at the top of DevTools. In the filter box, type 'api'."
                            )

                            helpStepRow(
                                number: "4",
                                title: "Copy the Authorization Header",
                                text: "Click on any network request (e.g. 'messages' or 'science' or '@me'). Scroll down to 'Request Headers', find 'Authorization', and copy that value!"
                            )
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // METHOD 2: BOT TOKEN
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("METHOD 2: DISCORD BOT TOKEN")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(goldAccent)
                                Spacer()
                                Text("For Server Bots")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(goldAccent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(goldAccent.opacity(0.15))
                                    .clipShape(Capsule())
                            }

                            Text("If you prefer not to use your personal user account, you can create a free Bot at discord.com/developers/applications, go to the Bot tab, reset/copy the token, and paste it directly into Bayan! (Include or omit 'Bot ' prefix - Bayan handles both automatically).")
                                .font(.system(size: 12.5))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Privacy Note
                        VStack(alignment: .leading, spacing: 6) {
                            Text("🔒 Privacy & Hardware Keychain Security")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Text("Bayan connects directly from your phone to Discord's official Gateway (wss://gateway.discord.gg). Your token is encrypted in Apple Secure Enclave Keychain and is never sent to any third-party servers.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        .padding(14)
                        .background(discordBlurple.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Discord Token Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingTokenHelpSheet = false
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(goldAccent)
                }
            }
        }
    }

    private func helpStepRow(number: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(discordBlurple)
                    .frame(width: 26, height: 26)
                Text(number)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(text)
                    .font(.system(size: 12.5))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}
