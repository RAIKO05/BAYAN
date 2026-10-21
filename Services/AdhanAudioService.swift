import Foundation
import AVFoundation

// MARK: - Adhan Audio Playback Service
/// Manages high-fidelity audio playback of the authentic Adhan (Call to Prayer)
/// using the bundled audio resource with remote streaming fallback.
@Observable
public final class AdhanAudioService: NSObject, AVAudioPlayerDelegate {
    public static let shared = AdhanAudioService()

    public var isPlaying: Bool = false
    public var currentPrayerName: String = "الأذان"
    public var currentTime: TimeInterval = 0
    public var duration: TimeInterval = 0

    private var audioPlayer: AVAudioPlayer?
    private var avPlayer: AVPlayer?
    private var progressTimer: Timer?

    private let fallbackStreamURL = URL(string: "https://raw.githubusercontent.com/abodehq/Athan-MP3/master/Sounds/Athan%20Makkah.mp3")!

    private override init() {
        super.init()
    }

    /// Plays the authentic Adhan audio for the specified prayer
    public func playAdhan(for prayerName: String = "الأذان") {
        currentPrayerName = prayerName

        // Configure audio session to play through speaker even in silent mode
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("⚠️ AVAudioSession configuration error for Adhan: \(error)")
        }

        // 1. Try bundled local MP3 first
        if let bundleUrl = Bundle.main.url(forResource: "adhan", withExtension: "mp3", subdirectory: "Audio") ??
                           Bundle.main.url(forResource: "adhan", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: bundleUrl)
                audioPlayer?.delegate = self
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                duration = audioPlayer?.duration ?? 0
                isPlaying = true
                startProgressTimer()
                print("📢 Playing bundled Adhan for \(prayerName)")
                return
            } catch {
                print("⚠️ Could not initialize AVAudioPlayer with bundled file: \(error)")
            }
        }

        // 2. Fallback to AVPlayer streaming
        let playerItem = AVPlayerItem(url: fallbackStreamURL)
        avPlayer = AVPlayer(playerItem: playerItem)
        avPlayer?.play()
        isPlaying = true
        print("📢 Streaming fallback Adhan for \(prayerName)")

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }

    /// Stops the Adhan playback immediately
    public func stopAdhan() {
        audioPlayer?.stop()
        audioPlayer = nil
        avPlayer?.pause()
        avPlayer = nil
        progressTimer?.invalidate()
        progressTimer = nil
        isPlaying = false
        currentTime = 0
        print("⏹ Adhan playback stopped.")
    }

    /// Toggles play/stop for the given prayer
    public func toggleAdhan(for prayerName: String = "الأذان") {
        if isPlaying {
            stopAdhan()
        } else {
            playAdhan(for: prayerName)
        }
    }

    // MARK: - AVAudioPlayerDelegate
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.stopAdhan()
        }
    }

    @objc private func playerItemDidReachEnd() {
        DispatchQueue.main.async {
            self.stopAdhan()
        }
    }

    private func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer, self.isPlaying else { return }
            self.currentTime = player.currentTime
        }
    }
}
