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

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var statusObservation: NSKeyValueObservation?

    // Gapless Verse Pre-buffering
    private var preloadedPlayerItem: AVPlayerItem?
    private var preloadedTarget: (surahId: Int, ayah: Int, reciterId: String)?

    public override init() {
        super.init()
        let savedQariId = QuranSyncManager.shared.lastQariId
        if let saved = Reciter.standardCatalog.first(where: { $0.id == savedQariId }) {
            self.currentReciter = saved
        }
        configureAudioSessionForPlayback()
        setupRemoteCommandCenter()
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
        cleanupTimeObserver()
        statusObservation?.invalidate()
        statusObservation = nil

        player?.pause()

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
        playerItem.preferredForwardBufferDuration = 10.0

        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.automaticallyWaitsToMinimizeStalling = true
        newPlayer.volume = 1.0
        self.player = newPlayer

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

        setupTimeObserver()

        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        newPlayer.play()
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
        guard let surah = currentSurah else { return }

        switch repeatMode {
        case .repeatAyah(let count):
            if count == Int.max {
                // Continuous infinite loop of this single Ayah
                seek(to: 0)
                player?.play()
                isPlaying = true
                return
            }

            if remainingAyahRepeats > 1 {
                // Decrement and repeat same Ayah
                remainingAyahRepeats -= 1
                seek(to: 0)
                player?.play()
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
            isPlaying = true
            updateNowPlayingInfo()
        }
    }

    public func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    public func stop() {
        cleanupTimeObserver()
        statusObservation?.invalidate()
        statusObservation = nil
        player?.pause()
        isPlaying = false
        currentTime = 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
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
            return
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: "Surah \(surah.nameEnglish) (\(surah.nameArabic))",
            MPMediaItemPropertyArtist: "Ayah \(currentAyah) • \(currentReciter.nameEnglish)",
            MPMediaItemPropertyAlbumTitle: "The Holy Qur'an • Bayan",
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPMediaItemPropertyPlaybackDuration: duration > 0 ? duration : 1.0,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0
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
}
