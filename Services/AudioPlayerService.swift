import Foundation
import AVFoundation
import MediaPlayer

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

    public override init() {
        super.init()
        configureAudioSessionForPlayback()
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

        guard let url = activeReciter.audioUrl(surah: surah.id, ayah: ayah) else {
            print("❌ Invalid audio URL for Surah \(surah.id), Ayah \(ayah)")
            return
        }

        print("▶️ Loading Quran recitation: \(url)")

        configureAudioSessionForPlayback()
        cleanupTimeObserver()
        statusObservation?.invalidate()
        statusObservation = nil

        player?.pause()

        let playerItem = AVPlayerItem(url: url)
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
            player?.pause()
            isPlaying = false
        } else {
            configureAudioSessionForPlayback()
            player?.play()
            isPlaying = true
        }
    }

    public func stop() {
        cleanupTimeObserver()
        statusObservation?.invalidate()
        statusObservation = nil
        player?.pause()
        isPlaying = false
        currentTime = 0.0
    }
}
