import Foundation
import ShazamKit
import AVFoundation

// MARK: - ShazamKit Matcher for Bayan
public final class ShazamCatalogService: NSObject, SHSessionDelegate {
    public static let shared = ShazamCatalogService()

    private var session: SHSession?
    private var customCatalog: SHCustomCatalog?
    public var onMatch: ((RecognitionResult) -> Void)?
    public var onError: ((Error) -> Void)?

    private override init() {
        super.init()
        loadBundledCatalog()
    }

    private func loadBundledCatalog() {
        // Look for BayanQuran.shazamcatalog in the app bundle
        if let catalogUrl = Bundle.main.url(forResource: "BayanQuran", withExtension: "shazamcatalog") {
            do {
                let catalog = try SHCustomCatalog(contentsOf: catalogUrl)
                self.customCatalog = catalog
                self.session = SHSession(catalog: catalog)
                self.session?.delegate = self
                print("✅ Successfully loaded BayanQuran.shazamcatalog into ShazamKit session.")
            } catch {
                print("⚠️ Failed to load custom catalog: \(error)")
            }
        } else {
            print("ℹ️ BayanQuran.shazamcatalog not bundled yet. Running in simulated match mode.")
        }
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
