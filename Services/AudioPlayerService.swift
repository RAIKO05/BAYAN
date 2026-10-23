import Foundation
import AVFoundation
import MediaPlayer
#if canImport(UIKit)
import UIKit
#endif
#if canImport(ActivityKit)
import ActivityKit
#endif

// MARK: - Quran Verse Queue Player Item
/// Custom AVPlayerItem tracking exact Surah, Ayah, and Reciter identity
/// enabling seamless, zero-gap hardware transitions via AVQueuePlayer.
public final class QuranVersePlayerItem: AVPlayerItem {
    public let surah: Surah
    public let ayah: Int
    public let reciter: Reciter

    public init(url: URL, surah: Surah, ayah: Int, reciter: Reciter) {
        self.surah = surah
        self.ayah = ayah
        self.reciter = reciter
        let asset = AVURLAsset(url: url)
        super.init(asset: asset, automaticallyLoadedAssetKeys: ["duration", "playable"])
        self.preferredForwardBufferDuration = 10.0
        self.audioTimePitchAlgorithm = .timeDomain
    }
}

// MARK: - High-Fidelity Gapless Quran Recitation Audio Service
@Observable
public final class AudioPlayerService: NSObject {
    public static let shared = AudioPlayerService()

    public var isPlaying: Bool = false
    public var currentSurah: Surah?
    public var currentAyah: Int = 1
    public var currentReciter: Reciter = Reciter.standardCatalog[0]
    public var currentTime: Double = 0.0
    public var duration: Double = 1.0

    // MARK: - Verse Audio Repeat / Memorization (Hifz Mode & A-B Loop)
    public enum RepeatMode: Equatable {
        case off
        case repeatSurah
        case repeatAyah(count: Int) // 1x continuous loop (Int.max) or specific count (3x, 5x, 10x)
        case repeatAB(startAyah: Int, endAyah: Int, count: Int) // A-B Range Memorization Loop

        public var title: String {
            switch self {
            case .off: return "Off"
            case .repeatSurah: return "Surah"
            case .repeatAyah(let count):
                return count == Int.max ? "1" : "\(count)x"
            case .repeatAB(let a, let b, let count):
                return count == Int.max ? "\(a)-\(b) ∞" : "\(a)-\(b) \(count)x"
            }
        }

        public var iconName: String {
            switch self {
            case .off: return "repeat"
            case .repeatSurah: return "repeat.circle.fill"
            case .repeatAyah: return "repeat.1.circle.fill"
            case .repeatAB: return "repeat.1.ar"
            }
        }

        public var isRepeating: Bool {
            self != .off
        }
    }

    public var repeatMode: RepeatMode = .off
    public var remainingAyahRepeats: Int = 0

    // A-B Loop Range State
    public var abStartAyah: Int = 1
    public var abEndAyah: Int = 1
    public var abRepeatCount: Int = 3
    public var abCurrentIteration: Int = 1

    public var isABLoopActive: Bool {
        if case .repeatAB = repeatMode { return true }
        return false
    }

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

    // MARK: - Core Audio Engine (AVQueuePlayer for Zero-Gap Playback)
    private var player: AVQueuePlayer?
    private var timeObserverToken: Any?
    private var currentItemObservation: NSKeyValueObservation?
    private var timeControlStatusObservation: NSKeyValueObservation?
    private var statusObservation: NSKeyValueObservation?

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

    // MARK: - Continuous Recitation Playback Engine (Gapless AVQueuePlayer)
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

        configureAudioSessionForPlayback()
        cleanupCurrentItemObservations()

        speechWatchdogTask?.cancel()
        speechWatchdogTask = nil
        if speechSynthesizer?.isSpeaking == true {
            speechSynthesizer?.stopSpeaking(at: .immediate)
        }
        isSpeakingTranslation = false

        guard let firstItem = makePlayerItem(surah: surah, ayah: ayah, reciter: activeReciter) else {
            print("❌ Invalid audio URL for Surah \(surah.id), Ayah \(ayah)")
            return
        }

        // Trigger smart lookahead pre-caching for upcoming Ayahs in the background
        QuranAudioCacheManager.shared.prefetchUpcomingAyahs(
            reciter: activeReciter,
            surah: surah,
            currentAyah: ayah,
            count: 5
        )

        if let existing = self.player {
            existing.removeAllItems()
            existing.insert(firstItem, after: nil)
            enqueueUpcomingAyahs(startingAfter: ayah, in: surah, reciter: activeReciter, count: 1)
            existing.play()
            if playbackRate != 1.0 {
                existing.rate = playbackRate
            }
        } else {
            cleanupTimeObserver()
            let newPlayer = AVQueuePlayer(items: [firstItem])
            newPlayer.automaticallyWaitsToMinimizeStalling = true
            newPlayer.volume = 1.0
            self.player = newPlayer
            enqueueUpcomingAyahs(startingAfter: ayah, in: surah, reciter: activeReciter, count: 1)
            setupTimeObserver()
            setupPlayerObservations(newPlayer)
            newPlayer.play()
            if playbackRate != 1.0 {
                newPlayer.rate = playbackRate
            }
        }

        observeItem(firstItem)

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

        #if canImport(ActivityKit)
        QuranLyricsLiveActivityManager.shared.startOrUpdate(
            surah: surah,
            ayah: ayah,
            reciter: activeReciter,
            isPlaying: true
        )
        #endif

        updateNowPlayingInfo()
    }

    private func makePlayerItem(surah: Surah, ayah: Int, reciter: Reciter) -> QuranVersePlayerItem? {
        // 1. Check permanent offline downloads
        let permanentUrl = QuranAudioDownloadService.shared.localAudioUrl(reciterId: reciter.id, surah: surah.id, ayah: ayah)
        // 2. Check ephemeral smart stream lookahead cache
        let cachedUrl = QuranAudioCacheManager.shared.cachedAudioUrl(reciterId: reciter.id, surah: surah.id, ayah: ayah)

        guard let url = permanentUrl ?? cachedUrl ?? reciter.audioUrl(surah: surah.id, ayah: ayah) else { return nil }
        return QuranVersePlayerItem(url: url, surah: surah, ayah: ayah, reciter: reciter)
    }

    private func isItemAlreadyEnqueued(surahId: Int, ayah: Int) -> Bool {
        guard let items = player?.items() else { return false }
        for item in items {
            if let verseItem = item as? QuranVersePlayerItem {
                if verseItem.surah.id == surahId && verseItem.ayah == ayah {
                    return true
                }
            }
        }
        return false
    }

    private func enqueueUpcomingAyahs(startingAfter ayah: Int, in surah: Surah, reciter: Reciter, count: Int = 1) {
        guard let p = self.player else { return }

        // Whole-surah reciters stream a single continuous surah audio file
        if reciter.id == "omardiaa" || reciter.id == "kazabri_warsh" {
            return
        }

        // 1. Single Ayah Repeat Mode
        if case .repeatAyah(let loopCount) = repeatMode {
            if loopCount == Int.max || remainingAyahRepeats > 1 {
                if let repeatItem = makePlayerItem(surah: surah, ayah: ayah, reciter: reciter) {
                    if !isItemAlreadyEnqueued(surahId: surah.id, ayah: ayah) {
                        p.insert(repeatItem, after: nil)
                    }
                }
                return
            }
        }

        // 2. A-B Memorization Loop Mode
        if case .repeatAB(let start, let end, let loopCount) = repeatMode {
            if ayah < end {
                let nextAyah = ayah + 1
                if let item = makePlayerItem(surah: surah, ayah: nextAyah, reciter: reciter) {
                    if !isItemAlreadyEnqueued(surahId: surah.id, ayah: nextAyah) {
                        p.insert(item, after: nil)
                    }
                }
            } else if ayah >= end {
                if loopCount == Int.max || abCurrentIteration < loopCount {
                    if let loopItem = makePlayerItem(surah: surah, ayah: start, reciter: reciter) {
                        if !isItemAlreadyEnqueued(surahId: surah.id, ayah: start) {
                            p.insert(loopItem, after: nil)
                        }
                    }
                }
            }
            return
        }

        // 3. Normal Sequential Progression
        if ayah < surah.totalAyahs {
            let nextAyah = ayah + 1
            if let item = makePlayerItem(surah: surah, ayah: nextAyah, reciter: reciter) {
                if !isItemAlreadyEnqueued(surahId: surah.id, ayah: nextAyah) {
                    p.insert(item, after: nil)
                }
            }
        } else if repeatMode == .repeatSurah {
            // Repeat Surah: Loop back to Ayah 1
            if let loopItem = makePlayerItem(surah: surah, ayah: 1, reciter: reciter) {
                if !isItemAlreadyEnqueued(surahId: surah.id, ayah: 1) {
                    p.insert(loopItem, after: nil)
                }
            }
        } else if surah.id < 114, let nextSurah = QuranDataService.shared.surah(for: surah.id + 1) {
            // Continuous Surah Autoplay ("Album Mode"): Queue first Ayah of next Surah!
            if let nextItem = makePlayerItem(surah: nextSurah, ayah: 1, reciter: reciter) {
                if !isItemAlreadyEnqueued(surahId: nextSurah.id, ayah: 1) {
                    p.insert(nextItem, after: nil)
                }
            }
        }
    }

    private func setupPlayerObservations(_ qPlayer: AVQueuePlayer) {
        currentItemObservation?.invalidate()
        currentItemObservation = qPlayer.observe(\.currentItem, options: [.new]) { [weak self] player, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let nextItem = player.currentItem as? QuranVersePlayerItem {
                    self.handleVerseItemTransition(to: nextItem)
                } else if player.items().isEmpty {
                    self.handleQueueDidEnd()
                }
            }
        }

        timeControlStatusObservation?.invalidate()
        timeControlStatusObservation = qPlayer.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // Buffer Underrun Stall Watchdog: If playback should be active, immediately resume once buffered
                if self.isPlaying && player.timeControlStatus == .paused && player.currentItem?.status == .readyToPlay {
                    player.play()
                    if self.playbackRate != 1.0 {
                        player.rate = self.playbackRate
                    }
                }
            }
        }
    }

    private func handleVerseItemTransition(to item: QuranVersePlayerItem) {
        // 1. Bedtime Sleep Timer: End of Current Ayah Check
        if sleepTimerOption == .endOfAyah {
            Task { @MainActor [weak self] in
                await self?.fadeVolumeAndPause()
            }
            return
        }

        // 2. Dual Audio Mode: Speak English Translation Before Continuing
        if isDualAudioEnabled {
            let previousAyah = currentAyah
            let translation = QuranVerseText.translation(surahId: item.surah.id, ayahNumber: previousAyah)
            let clean = translation.trimmingCharacters(in: .whitespacesAndNewlines)
            if !clean.isEmpty {
                player?.pause()
                speakTranslation(clean) { [weak self] in
                    self?.player?.play()
                }
            }
        }

        // 3. Repeat Mode Accounting: Handle repeatAyah counter
        if case .repeatAyah(let count) = repeatMode {
            if item.ayah == currentAyah {
                if remainingAyahRepeats > 1 {
                    self.remainingAyahRepeats -= 1
                } else {
                    self.remainingAyahRepeats = count
                }
            } else {
                self.remainingAyahRepeats = count
            }
        }

        // 4. A-B Loop Iteration Accounting
        if case .repeatAB(let start, let end, _) = repeatMode {
            if item.ayah == start && currentAyah == end {
                self.abCurrentIteration += 1
            }
        }

        self.currentSurah = item.surah
        self.currentAyah = item.ayah
        self.currentReciter = item.reciter
        self.currentTime = 0.0

        observeItem(item)

        // Silently pre-cache next 5 upcoming Ayahs to local disk cache
        QuranAudioCacheManager.shared.prefetchUpcomingAyahs(
            reciter: item.reciter,
            surah: item.surah,
            currentAyah: item.ayah,
            count: 5
        )

        QuranSyncManager.shared.updateLastRead(
            surahId: item.surah.id,
            ayahId: item.ayah,
            page: item.surah.startPage,
            qariId: item.reciter.id,
            audioTime: 0.0
        )

        #if canImport(ActivityKit)
        QuranLyricsLiveActivityManager.shared.startOrUpdate(
            surah: item.surah,
            ayah: item.ayah,
            reciter: item.reciter,
            isPlaying: true
        )
        #endif

        updateNowPlayingInfo()

        // 5. Lookahead Queue: Enqueue exactly ONE upcoming verse with duplicate protection
        enqueueUpcomingAyahs(startingAfter: item.ayah, in: item.surah, reciter: item.reciter, count: 1)
    }

    private func handleQueueDidEnd() {
        guard let surah = currentSurah else {
            isPlaying = false
            return
        }

        if case .repeatAyah = repeatMode {
            play(surah: surah, ayah: currentAyah, reciter: currentReciter)
            return
        }

        if case .repeatAB(let start, _, let loopCount) = repeatMode {
            if loopCount == Int.max || abCurrentIteration < loopCount {
                self.abCurrentIteration += 1
                play(surah: surah, ayah: start, reciter: currentReciter)
                return
            }
        }

        if repeatMode == .repeatSurah {
            play(surah: surah, ayah: 1, reciter: currentReciter)
            return
        }

        if surah.id < 114, let nextSurah = QuranDataService.shared.surah(for: surah.id + 1) {
            print("➡️ Seamlessly transitioning to next Surah: \(nextSurah.nameEnglish)")
            play(surah: nextSurah, ayah: 1, reciter: currentReciter)
            return
        }

        // Reached end of Quran
        isPlaying = false
        #if canImport(ActivityKit)
        QuranLyricsLiveActivityManager.shared.updatePlaybackState(isPlaying: false)
        #endif
        updateNowPlayingInfo()
    }

    private func observeItem(_ item: AVPlayerItem) {
        statusObservation?.invalidate()
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] playerItem, _ in
            guard let self = self else { return }
            if playerItem.status == .readyToPlay {
                let itemDuration = playerItem.duration.seconds
                if itemDuration.isFinite && !itemDuration.isNaN && itemDuration > 0 {
                    DispatchQueue.main.async {
                        self.duration = itemDuration
                    }
                }
                // Watchdog: If marked playing, ensure player is actively decoding audio
                if self.isPlaying {
                    DispatchQueue.main.async {
                        self.player?.play()
                        if self.playbackRate != 1.0 {
                            self.player?.rate = self.playbackRate
                        }
                    }
                }
            } else if playerItem.status == .failed {
                print("❌ AVPlayerItem failed: \(String(describing: playerItem.error))")
                DispatchQueue.main.async {
                    self.player?.advanceToNextItem()
                }
            }
        }
    }

    private func cleanupCurrentItemObservations() {
        statusObservation?.invalidate()
        statusObservation = nil
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
        } else if surah.id < 114, let nextSurah = QuranDataService.shared.surah(for: surah.id + 1) {
            play(surah: nextSurah, ayah: 1, reciter: currentReciter)
        }
    }

    public func previousAyah() {
        guard let surah = currentSurah else { return }
        if currentAyah > 1 {
            play(surah: surah, ayah: currentAyah - 1, reciter: currentReciter)
        } else if surah.id > 1, let prevSurah = QuranDataService.shared.surah(for: surah.id - 1) {
            play(surah: prevSurah, ayah: prevSurah.totalAyahs, reciter: currentReciter)
        } else {
            seek(to: 0)
        }
    }

    // MARK: - Cycle Repeat Mode (Standard Apple Music / Spotify Pattern)
    public func cycleRepeatMode() {
        switch repeatMode {
        case .off:
            repeatMode = .repeatSurah
            remainingAyahRepeats = 0
        case .repeatSurah:
            repeatMode = .repeatAyah(count: Int.max)
            remainingAyahRepeats = Int.max
        case .repeatAyah:
            repeatMode = .off
            remainingAyahRepeats = 0
        case .repeatAB:
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

    // MARK: - A-B Loop Memorization Engine
    public func enableABLoop(startAyah: Int, endAyah: Int, count: Int = 3) {
        let safeStart = max(1, min(startAyah, endAyah))
        let safeEnd = max(startAyah, endAyah)
        self.abStartAyah = safeStart
        self.abEndAyah = safeEnd
        self.abRepeatCount = count
        self.abCurrentIteration = 1
        self.repeatMode = .repeatAB(startAyah: safeStart, endAyah: safeEnd, count: count)

        if let surah = currentSurah {
            if currentAyah < safeStart || currentAyah > safeEnd {
                play(surah: surah, ayah: safeStart, reciter: currentReciter)
            }
        }
    }

    public func disableABLoop() {
        self.repeatMode = .off
        self.abCurrentIteration = 1
    }

    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
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
        #if canImport(ActivityKit)
        QuranLyricsLiveActivityManager.shared.updatePlaybackState(isPlaying: false)
        #endif
        updateNowPlayingInfo()
    }

    public func resume() {
        guard !isPlaying else { return }
        configureAudioSessionForPlayback()
        player?.play()
        if playbackRate != 1.0 {
            player?.rate = playbackRate
        }
        isPlaying = true
        #if canImport(ActivityKit)
        QuranLyricsLiveActivityManager.shared.updatePlaybackState(isPlaying: true)
        #endif
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
        cleanupCurrentItemObservations()
        currentItemObservation?.invalidate()
        currentItemObservation = nil
        timeControlStatusObservation?.invalidate()
        timeControlStatusObservation = nil
        player?.pause()
        player?.removeAllItems()
        isPlaying = false
        currentTime = 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        #if canImport(ActivityKit)
        QuranLyricsLiveActivityManager.shared.endActivity()
        #endif
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
        utterance.rate = 0.48 // Dignified, serene pace
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        isSpeakingTranslation = true
        speechSynthesizer?.speak(utterance)

        let wordCount = text.split(separator: " ").count
        let timeoutSeconds = max(4.0, Double(wordCount) * 0.45 + 3.0)
        speechWatchdogTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
            guard let self = self, !Task.isCancelled, self.isSpeakingTranslation else { return }
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
                if self.isPlaying {
                    self.pause()
                }
            }
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
            self.player?.play()
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
