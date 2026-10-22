import Foundation
import AVFoundation
import MediaPlayer
#if canImport(UIKit)
import UIKit
#endif

@Observable
public final class AudioPlayerService: NSObject {
    public static let shared = AudioPlayerService()

    public var isPlaying: Bool = false
    public var currentSurah: Surah?
    public var currentAyah: Int = 1
    public var currentReciter: Reciter = Reciter.standardCatalog[0]
    public var currentTime: Double = 0.0
    public var duration: Double = 1.0

    // MARK: - Verse Audio Repeat / Memorization (Hifz Mode)
    public enum RepeatMode: Equatable {
        case off
        case repeatAyah(count: Int) // 3x, 5x, 10x, or Int.max (continuous loop)
        case repeatSurah

        public var title: String {
            switch self {
            case .off: return "Off"
            case .repeatAyah(let count):
                return count == Int.max ? "Loop" : "\(count)x"
            case .repeatSurah: return "Surah"
            }
        }

        public var iconName: String {
            switch self {
            case .off: return "repeat"
            case .repeatAyah(let count):
                return count == Int.max ? "repeat.1.circle.fill" : "repeat.circle.fill"
            case .repeatSurah: return "repeat.circle.fill"
            }
        }

        public var isRepeating: Bool {
            self != .off
        }
    }

    public var repeatMode: RepeatMode = .off
    public var remainingAyahRepeats: Int = 0

    // MARK: - Recitation Speed & Pitch Preservation
    public var playbackRate: Float = 1.0

    // MARK: - Bedtime Sleep Timer
    public enum SleepTimerOption: Equatable, CaseIterable {
        case off
        case minutes15
        case minutes30
        case minutes45
        case minutes60
        case endOfAyah
        case endOfSurah

        public var title: String {
            switch self {
            case .off: return "Off"
            case .minutes15: return "15 Minutes"
            case .minutes30: return "30 Minutes"
            case .minutes45: return "45 Minutes"
            case .minutes60: return "60 Minutes"
            case .endOfAyah: return "End of Current Ayah"
            case .endOfSurah: return "End of Current Surah"
            }
        }

        public var iconName: String {
            switch self {
            case .off: return "moon.zzz"
            case .minutes15, .minutes30, .minutes45, .minutes60: return "timer"
            case .endOfAyah: return "stop.circle"
            case .endOfSurah: return "book.closed"
            }
        }

        public var durationSeconds: Int? {
            switch self {
            case .minutes15: return 15 * 60
            case .minutes30: return 30 * 60
            case .minutes45: return 45 * 60
            case .minutes60: return 60 * 60
            default: return nil
            }
        }
    }

    public var sleepTimerOption: SleepTimerOption = .off
    public var sleepTimerRemainingSeconds: Int = 0
    @ObservationIgnored private var sleepTimerTask: Task<Void, Never>?

    // MARK: - Dual Audio Mode (Arabic Recitation + English Translation Voiceover)
    public var isDualAudioEnabled: Bool = false
    public var isSpeakingTranslation: Bool = false
    @ObservationIgnored private var speechSynthesizer: AVSpeechSynthesizer?
    @ObservationIgnored private var speechWatchdogTask: Task<Void, Never>?

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var statusObservation: NSKeyValueObservation?

    // Gapless Verse Pre-buffering
    private var preloadedPlayerItem: AVPlayerItem?
    private var preloadedTarget: (surahId: Int, ayah: Int, reciterId: String)?
    private var wasPlayingBeforeInterruption = false

    public override init() {
        super.init()
        let savedQariId = QuranSyncManager.shared.lastQariId
        if let saved = Reciter.standardCatalog.first(where: { $0.id == savedQariId }) {
            self.currentReciter = saved
        }
        let savedRate = UserDefaults.standard.float(forKey: "bayan_audio_playback_rate")
        if savedRate >= 0.5 && savedRate <= 2.5 {
            self.playbackRate = savedRate
        }
        self.isDualAudioEnabled = UserDefaults.standard.bool(forKey: "bayan_dual_audio_enabled")

        configureAudioSessionForPlayback()
        setupRemoteCommandCenter()
        setupAudioSessionNotifications()
    }

    public func configureAudioSessionForPlayback() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("⚠️ Playback audio session configuration failed: \(error)")
        }
    }

    public func play(surah: Surah, ayah: Int = 1, reciter: Reciter? = nil) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.play(surah: surah, ayah: ayah, reciter: reciter)
            }
            return
        }

        let activeReciter = reciter ?? self.currentReciter
        self.currentSurah = surah
        self.currentAyah = ayah
        self.currentReciter = activeReciter

        // Prefer offline downloaded audio cache if available
        let localUrl = QuranAudioDownloadService.shared.localAudioUrl(reciterId: activeReciter.id, surah: surah.id, ayah: ayah)
        let playbackUrl = localUrl ?? activeReciter.audioUrl(surah: surah.id, ayah: ayah)

        guard let url = playbackUrl else {
            print("❌ Invalid audio URL for Surah \(surah.id), Ayah \(ayah)")
            return
        }

        if localUrl != nil {
            print("💾 Playing from offline local cache: \(url.lastPathComponent)")
        } else {
            print("▶️ Streaming Quran recitation: \(url)")
        }

        configureAudioSessionForPlayback()
        statusObservation?.invalidate()
        statusObservation = nil

        speechWatchdogTask?.cancel()
        speechWatchdogTask = nil
        if speechSynthesizer?.isSpeaking == true {
            speechSynthesizer?.stopSpeaking(at: .immediate)
        }
        isSpeakingTranslation = false

        let playerItem: AVPlayerItem
        if let preloaded = preloadedPlayerItem,
           let target = preloadedTarget,
           target.surahId == surah.id && target.ayah == ayah && target.reciterId == activeReciter.id {
            playerItem = preloaded
            preloadedPlayerItem = nil
            preloadedTarget = nil
        } else {
            playerItem = AVPlayerItem(url: url)
        }
        playerItem.preferredForwardBufferDuration = 5.0
        playerItem.audioTimePitchAlgorithm = .timeDomain

        // Continuous zero-stop item replacement on the persistent AVPlayer
        if let existingPlayer = self.player {
            existingPlayer.replaceCurrentItem(with: playerItem)
            existingPlayer.playImmediately(atRate: playbackRate)
        } else {
            cleanupTimeObserver()
            let newPlayer = AVPlayer(playerItem: playerItem)
            newPlayer.automaticallyWaitsToMinimizeStalling = false
            newPlayer.volume = 1.0
            self.player = newPlayer
            setupTimeObserver()
            newPlayer.playImmediately(atRate: playbackRate)
        }

        // Observe player item status to catch duration and errors
        statusObservation = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self = self else { return }
            if item.status == .readyToPlay {
                let itemDuration = item.duration.seconds
                if itemDuration.isFinite && !itemDuration.isNaN && itemDuration > 0 {
                    DispatchQueue.main.async {
                        self.duration = itemDuration
                    }
                }
            } else if item.status == .failed {
                print("❌ AVPlayerItem failed: \(String(describing: item.error))")
            }
        }

        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        self.isPlaying = true

        if case .repeatAyah(let count) = repeatMode {
            self.remainingAyahRepeats = count
        }

        QuranSyncManager.shared.updateLastRead(
            surahId: surah.id,
            ayahId: ayah,
            page: surah.startPage,
            qariId: activeReciter.id,
            audioTime: 0.0
        )

        updateNowPlayingInfo()

        // Asynchronously preload next Ayah in background for seamless gapless playback
        preloadNextAyahAsync(surah: surah, nextAyah: ayah + 1, reciter: activeReciter)
    }

    private func preloadNextAyahAsync(surah: Surah, nextAyah: Int, reciter: Reciter) {
        guard nextAyah <= surah.totalAyahs else {
            preloadedPlayerItem = nil
            preloadedTarget = nil
            return
        }

        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let localUrl = QuranAudioDownloadService.shared.localAudioUrl(reciterId: reciter.id, surah: surah.id, ayah: nextAyah)
            guard let nextUrl = localUrl ?? reciter.audioUrl(surah: surah.id, ayah: nextAyah) else { return }

            let item = AVPlayerItem(url: nextUrl)
            item.preferredForwardBufferDuration = 10.0
            item.audioTimePitchAlgorithm = .timeDomain

            DispatchQueue.main.async {
                self.preloadedPlayerItem = item
                self.preloadedTarget = (surah.id, nextAyah, reciter.id)
            }
        }
    }

    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            if let currentItem = self.player?.currentItem,
               currentItem.duration.seconds.isFinite,
               !currentItem.duration.seconds.isNaN,
               currentItem.duration.seconds > 0 {
                self.duration = currentItem.duration.seconds
            }
        }
    }

    private func cleanupTimeObserver() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }

    public func seek(to seconds: Double) {
        let clampedSeconds = max(0, min(seconds, duration))
        let targetTime = CMTime(seconds: clampedSeconds, preferredTimescale: 600)
        player?.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        self.currentTime = clampedSeconds
        updateNowPlayingInfo()
    }

    public func skipForward(by seconds: Double = 15) {
        seek(to: currentTime + seconds)
    }

    public func skipBackward(by seconds: Double = 15) {
        seek(to: currentTime - seconds)
    }

    public func nextAyah() {
        guard let surah = currentSurah else { return }
        if currentAyah < surah.totalAyahs {
            play(surah: surah, ayah: currentAyah + 1, reciter: currentReciter)
        }
    }

    public func previousAyah() {
        guard let surah = currentSurah else { return }
        if currentAyah > 1 {
            play(surah: surah, ayah: currentAyah - 1, reciter: currentReciter)
        } else {
            seek(to: 0)
        }
    }

    @objc private func playerItemDidFinishPlaying() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let surah = self.currentSurah else { return }

            // 1. Bedtime Sleep Timer: End of Current Ayah
            if self.sleepTimerOption == .endOfAyah {
                Task { @MainActor [weak self] in
                    await self?.fadeVolumeAndPause()
                }
                return
            }

            // 2. Dual Audio Mode: Speak English Translation Before Advancing
            if self.isDualAudioEnabled {
                let translation = QuranVerseText.translation(surahId: surah.id, ayahNumber: self.currentAyah)
                let clean = translation.trimmingCharacters(in: .whitespacesAndNewlines)
                if !clean.isEmpty {
                    self.speakTranslation(clean) { [weak self] in
                        guard let self = self, let activeSurah = self.currentSurah else { return }
                        self.advanceAfterCurrentAyah(surah: activeSurah)
                    }
                    return
                }
            }

            // 3. Normal Sequential Progression or Repeat Mode (Seamless Zero-Stop)
            self.advanceAfterCurrentAyah(surah: surah)
        }
    }

    public func advanceAfterCurrentAyah(surah: Surah) {
        // Bedtime Sleep Timer: End of Surah Check
        if sleepTimerOption == .endOfSurah && currentAyah >= surah.totalAyahs {
            Task { @MainActor [weak self] in
                await self?.fadeVolumeAndPause()
            }
            return
        }

        switch repeatMode {
        case .repeatAyah(let count):
            if count == Int.max {
                // Continuous infinite loop of this single Ayah
                seek(to: 0)
                player?.play()
                if playbackRate != 1.0 { player?.rate = playbackRate }
                isPlaying = true
                return
            }

            if remainingAyahRepeats > 1 {
                // Decrement and repeat same Ayah
                remainingAyahRepeats -= 1
                seek(to: 0)
                player?.play()
                if playbackRate != 1.0 { player?.rate = playbackRate }
                isPlaying = true
                return
            } else {
                // Finished count repeats, reset counter for next Ayah
                remainingAyahRepeats = count
                if currentAyah < surah.totalAyahs {
                    play(surah: surah, ayah: currentAyah + 1, reciter: currentReciter)
                } else {
                    isPlaying = false
                }
            }

        case .repeatSurah:
            if currentAyah < surah.totalAyahs {
                play(surah: surah, ayah: currentAyah + 1, reciter: currentReciter)
            } else {
                // Loop back to Ayah 1 of the Surah
                play(surah: surah, ayah: 1, reciter: currentReciter)
            }

        case .off:
            if currentAyah < surah.totalAyahs {
                // Auto-advance sequentially to the next Ayah
                play(surah: surah, ayah: currentAyah + 1, reciter: currentReciter)
            } else {
                // Reached the end of the Surah
                isPlaying = false
            }
        }
    }

    // MARK: - Cycle Repeat Mode for Memorization (Hifz)
    public func cycleRepeatMode() {
        switch repeatMode {
        case .off:
            repeatMode = .repeatAyah(count: 3)
            remainingAyahRepeats = 3
        case .repeatAyah(let count) where count == 3:
            repeatMode = .repeatAyah(count: 5)
            remainingAyahRepeats = 5
        case .repeatAyah(let count) where count == 5:
            repeatMode = .repeatAyah(count: Int.max)
            remainingAyahRepeats = Int.max
        case .repeatAyah:
            repeatMode = .repeatSurah
            remainingAyahRepeats = 0
        case .repeatSurah:
            repeatMode = .off
            remainingAyahRepeats = 0
        }
    }

    public func setRepeatMode(_ mode: RepeatMode) {
        repeatMode = mode
        if case .repeatAyah(let count) = mode {
            remainingAyahRepeats = count
        } else {
            remainingAyahRepeats = 0
        }
    }

    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            configureAudioSessionForPlayback()
            player?.play()
            if playbackRate != 1.0 {
                player?.rate = playbackRate
            }
            isPlaying = true
            updateNowPlayingInfo()
        }
    }

    public func pause() {
        speechWatchdogTask?.cancel()
        speechWatchdogTask = nil
        if speechSynthesizer?.isSpeaking == true {
            speechSynthesizer?.stopSpeaking(at: .immediate)
        }
        isSpeakingTranslation = false
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    public func resume() {
        guard !isPlaying, player != nil else { return }
        configureAudioSessionForPlayback()
        player?.play()
        if playbackRate != 1.0 {
            player?.rate = playbackRate
        }
        isPlaying = true
        updateNowPlayingInfo()
    }

    public func stop() {
        speechWatchdogTask?.cancel()
        speechWatchdogTask = nil
        if speechSynthesizer?.isSpeaking == true {
            speechSynthesizer?.stopSpeaking(at: .immediate)
        }
        isSpeakingTranslation = false
        sleepTimerTask?.cancel()
        sleepTimerTask = nil
        sleepTimerOption = .off
        sleepTimerRemainingSeconds = 0
        cleanupTimeObserver()
        statusObservation?.invalidate()
        statusObservation = nil
        player?.pause()
        isPlaying = false
        currentTime = 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Recitation Speed & Playback Rate Controls
    public func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        UserDefaults.standard.set(rate, forKey: "bayan_audio_playback_rate")
        if isPlaying {
            player?.rate = rate
        }
        updateNowPlayingInfo()
    }

    public func cyclePlaybackRate() {
        let rates: [Float] = [0.75, 1.0, 1.25, 1.5]
        if let idx = rates.firstIndex(of: playbackRate) {
            let nextIndex = (idx + 1) % rates.count
            setPlaybackRate(rates[nextIndex])
        } else {
            setPlaybackRate(1.0)
        }
    }

    // MARK: - Bedtime Sleep Timer Engine
    public func setSleepTimer(_ option: SleepTimerOption) {
        sleepTimerTask?.cancel()
        sleepTimerTask = nil
        sleepTimerOption = option

        if let seconds = option.durationSeconds {
            sleepTimerRemainingSeconds = seconds
            sleepTimerTask = Task { @MainActor [weak self] in
                while let self = self, self.sleepTimerRemainingSeconds > 0 {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    guard !Task.isCancelled else { return }
                    self.sleepTimerRemainingSeconds -= 1
                }
                guard let self = self, !Task.isCancelled, self.sleepTimerRemainingSeconds == 0 else { return }
                await self.fadeVolumeAndPause()
            }
        } else {
            sleepTimerRemainingSeconds = 0
        }
    }

    @MainActor
    public func fadeVolumeAndPause() async {
        guard let p = player, isPlaying else {
            sleepTimerOption = .off
            sleepTimerRemainingSeconds = 0
            return
        }
        let originalVolume = p.volume
        // Gentle 2-second volume fade out
        for step in stride(from: 10, through: 0, by: -1) {
            p.volume = (Float(step) / 10.0) * originalVolume
            try? await Task.sleep(nanoseconds: 180_000_000)
        }
        pause()
        p.volume = originalVolume
        sleepTimerOption = .off
        sleepTimerRemainingSeconds = 0
    }

    public var sleepTimerFormatted: String {
        let mins = sleepTimerRemainingSeconds / 60
        let secs = sleepTimerRemainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    // MARK: - Dual Audio Voiceover Synthesizer
    public func toggleDualAudio() {
        isDualAudioEnabled.toggle()
        UserDefaults.standard.set(isDualAudioEnabled, forKey: "bayan_dual_audio_enabled")
    }

    private func speakTranslation(_ text: String, fallback: @escaping () -> Void) {
        speechWatchdogTask?.cancel()
        speechWatchdogTask = nil

        if speechSynthesizer == nil {
            let synth = AVSpeechSynthesizer()
            synth.delegate = self
            self.speechSynthesizer = synth
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US") ?? AVSpeechSynthesisVoice(language: "en-GB")
        utterance.rate = 0.48 // Dignified, serene, easy-to-follow pace
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        isSpeakingTranslation = true
        speechSynthesizer?.speak(utterance)

        // Safety Watchdog: If AVSpeechSynthesizer fails to fire didFinish within reasonable time, advance anyway
        let wordCount = text.split(separator: " ").count
        let timeoutSeconds = max(4.0, Double(wordCount) * 0.45 + 3.0)
        speechWatchdogTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
            guard let self = self, !Task.isCancelled, self.isSpeakingTranslation else { return }
            print("⏱️ Translation speech watchdog advancing")
            self.isSpeakingTranslation = false
            fallback()
        }
    }

    // MARK: - Lock Screen & Control Center Remote Command Center
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if !self.isPlaying {
                self.togglePlayPause()
                return .success
            }
            return .commandFailed
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.isPlaying {
                self.togglePlayPause()
                return .success
            }
            return .commandFailed
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.togglePlayPause()
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.nextAyah()
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.previousAyah()
            return .success
        }

        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.seek(to: positionEvent.positionTime)
            return .success
        }
    }

    // MARK: - Now Playing Info & Lock Screen Dynamic Artwork
    public func updateNowPlayingInfo() {
        guard let surah = currentSurah else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            #if canImport(ActivityKit)
            QuranLyricsLiveActivityManager.shared.endActivity()
            #endif
            return
        }

        #if canImport(ActivityKit)
        QuranLyricsLiveActivityManager.shared.startOrUpdate(
            surah: surah,
            ayah: currentAyah,
            reciter: currentReciter,
            isPlaying: isPlaying
        )
        #endif

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: "Surah \(surah.nameEnglish) (\(surah.nameArabic))",
            MPMediaItemPropertyArtist: "Ayah \(currentAyah) • \(currentReciter.nameEnglish)",
            MPMediaItemPropertyAlbumTitle: "The Holy Qur'an • Bayan",
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPMediaItemPropertyPlaybackDuration: duration > 0 ? duration : 1.0,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? Double(playbackRate) : 0.0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: Double(playbackRate)
        ]

        #if canImport(UIKit)
        let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 512, height: 512)) { size in
            UIGraphicsImageRenderer(size: size).image { ctx in
                let rect = CGRect(origin: .zero, size: size)
                let colors = [
                    UIColor(red: 0.05, green: 0.08, blue: 0.16, alpha: 1.0).cgColor,
                    UIColor(red: 0.02, green: 0.03, blue: 0.08, alpha: 1.0).cgColor
                ]
                if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0]) {
                    ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
                }

                let borderPath = UIBezierPath(roundedRect: rect.insetBy(dx: 20, dy: 20), cornerRadius: 32)
                UIColor(red: 0.95, green: 0.78, blue: 0.35, alpha: 0.35).setStroke()
                borderPath.lineWidth = 3
                borderPath.stroke()

                let innerBorder = UIBezierPath(roundedRect: rect.insetBy(dx: 28, dy: 28), cornerRadius: 26)
                UIColor(red: 0.95, green: 0.78, blue: 0.35, alpha: 0.15).setStroke()
                innerBorder.lineWidth = 1
                innerBorder.stroke()

                let titleAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 42, weight: .bold),
                    .foregroundColor: UIColor(red: 0.95, green: 0.78, blue: 0.35, alpha: 1.0)
                ]
                let title = "BAYAN"
                let titleSize = title.size(withAttributes: titleAttrs)
                title.draw(at: CGPoint(x: (size.width - titleSize.width) / 2, y: size.height / 2 - 50), withAttributes: titleAttrs)

                let subAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 22, weight: .medium),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.85)
                ]
                let sub = "The Holy Qur'an"
                let subSize = sub.size(withAttributes: subAttrs)
                sub.draw(at: CGPoint(x: (size.width - subSize.width) / 2, y: size.height / 2 + 10), withAttributes: subAttrs)

                let surahAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 18, weight: .regular),
                    .foregroundColor: UIColor(red: 0.95, green: 0.78, blue: 0.35, alpha: 0.75)
                ]
                let surahLabel = surah.nameArabic
                let surahSize = surahLabel.size(withAttributes: surahAttrs)
                surahLabel.draw(at: CGPoint(x: (size.width - surahSize.width) / 2, y: size.height / 2 + 45), withAttributes: surahAttrs)
            }
        }
        info[MPMediaItemPropertyArtwork] = artwork
        #endif

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - Audio Session Interruption & Route Change Observers
    private func setupAudioSessionNotifications() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

            switch type {
            case .began:
                if self.isPlaying {
                    self.wasPlayingBeforeInterruption = true
                    self.pause()
                }
            case .ended:
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) && self.wasPlayingBeforeInterruption {
                        self.resume()
                    }
                }
                self.wasPlayingBeforeInterruption = false
            @unknown default:
                break
            }
        }

        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let userInfo = notification.userInfo,
                  let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

            if reason == .oldDeviceUnavailable {
                // Pauses immediately if AirPods / headphones disconnect to avoid blasting phone speakers
                if self.isPlaying {
                    self.pause()
                }
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.preloadedPlayerItem = nil
            self?.preloadedTarget = nil
        }
        #endif
    }
}

// MARK: - AVSpeechSynthesizerDelegate Conformance (Dual Audio English Translation)
extension AudioPlayerService: AVSpeechSynthesizerDelegate {
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isSpeakingTranslation else { return }
            self.speechWatchdogTask?.cancel()
            self.speechWatchdogTask = nil
            self.isSpeakingTranslation = false
            guard let surah = self.currentSurah else { return }
            self.advanceAfterCurrentAyah(surah: surah)
        }
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.speechWatchdogTask?.cancel()
            self?.speechWatchdogTask = nil
            self?.isSpeakingTranslation = false
        }
    }
}
