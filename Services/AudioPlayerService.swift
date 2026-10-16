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

    private var player: AVPlayer?
    private var timeObserver: Any?

    public override init() {
        super.init()
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    public func play(surah: Surah, ayah: Int = 1, reciter: Reciter? = nil) {
        let activeReciter = reciter ?? self.currentReciter
        self.currentSurah = surah
        self.currentAyah = ayah
        self.currentReciter = activeReciter

        guard let url = activeReciter.audioUrl(surah: surah.id, ayah: ayah) else { return }

        player?.pause()
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        player?.play()
        self.isPlaying = true

        QuranSyncManager.shared.updateLastRead(
            surahId: surah.id,
            ayahId: ayah,
            page: surah.startPage,
            qariId: activeReciter.id,
            audioTime: 0.0
        )
    }

    @objc private func playerItemDidFinishPlaying() {
        guard let surah = currentSurah else { return }
        if currentAyah < surah.totalAyahs {
            // Auto-advance sequentially to the next Ayah
            play(surah: surah, ayah: currentAyah + 1, reciter: currentReciter)
        } else {
            // Reached the end of the Surah
            isPlaying = false
        }
    }

    public func togglePlayPause() {
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else {
            player?.play()
            isPlaying = true
        }
    }

    public func stop() {
        player?.pause()
        isPlaying = false
        currentTime = 0.0
    }
}
