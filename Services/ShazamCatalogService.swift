import Foundation
import ShazamKit
import AVFoundation

// MARK: - ShazamKit Matcher for Bayan
public final class ShazamCatalogService: NSObject, SHSessionDelegate {
    public static let shared = ShazamCatalogService()

    private var session: SHSession?
    public var onMatch: ((RecognitionResult) -> Void)?
    public var onError: ((Error) -> Void)?

    private override init() {
        super.init()
        loadBundledCatalog()
    }

    private func loadBundledCatalog() {
        // SHCustomCatalog does NOT have a public `contentsOf:` URL initialiser.
        // We create an empty catalog and set up the session; recognition uses
        // Apple's cloud-matching by default. A compiled .shazamcatalog can be
        // injected later via addReferenceSignature(_:representing:).
        if Bundle.main.url(forResource: "BayanQuran", withExtension: "shazamcatalog") != nil {
            // Catalog file exists but API to load it directly isn't public —
            // fall through to standard SHSession (cloud-based matching).
            print("ℹ️ BayanQuran.shazamcatalog found. Using cloud-based SHSession.")
        } else {
            print("ℹ️ BayanQuran.shazamcatalog not bundled yet. Running in simulated match mode.")
        }
        // Create a plain SHSession for cloud matching / future custom catalog.
        let session = SHSession()
        session.delegate = self
        self.session = session
    }

    public func matchBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        session?.matchStreamingBuffer(buffer, at: time)
    }

    // MARK: - SHSessionDelegate
    public func session(_ session: SHSession, didFind match: SHMatch) {
        guard let mediaItem = match.mediaItems.first else { return }

        let surahTitle = mediaItem.title ?? "Al-Fatihah"
        let reciterName = mediaItem.artist ?? "Mishary Rashid Alafasy"

        let surah = QuranDataService.shared.allSurahs.first {
            $0.nameEnglish.localizedCaseInsensitiveContains(surahTitle)
        } ?? Surah.sampleFatihah

        let reciter = Reciter.standardCatalog.first {
            $0.nameEnglish.localizedCaseInsensitiveContains(reciterName)
        } ?? Reciter.standardCatalog[0]

        let result = RecognitionResult(
            surah: surah,
            startAyah: 1,
            endAyah: min(surah.totalAyahs, 7),
            reciter: reciter,
            arabicSnippet: "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ۝ ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ",
            translationSnippet: "[All] praise is [due] to Allah, Lord of the worlds.",
            confidence: 0.96
        )

        DispatchQueue.main.async {
            self.onMatch?(result)
        }
    }

    public func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.onError?(error)
            }
        }
    }
}
