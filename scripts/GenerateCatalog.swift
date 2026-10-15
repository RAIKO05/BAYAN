import Foundation
import AVFoundation
import ShazamKit

// MARK: - ShazamKit Custom Catalog Generator for Quran Recitations
// Run on macOS with: swift GenerateCatalog.swift

@available(macOS 12.0, iOS 15.0, *)
class QuranCatalogBuilder {
    let customCatalog = SHCustomCatalog()

    struct AudioReference {
        let surahId: Int
        let surahNameEnglish: String
        let surahNameArabic: String
        let ayahStart: Int
        let ayahEnd: Int
        let reciterName: String
        let riwayah: String
        let audioFileUrl: URL
    }

    func addAudioSignature(reference: AudioReference) async throws {
        print("⚡️ Generating signature for: \(reference.surahNameEnglish) by \(reference.reciterName)...")

        let audioFile = try AVAudioFile(forReading: reference.audioFileUrl)
        let signatureGenerator = SHSignatureGenerator()

        let format = audioFile.processingFormat
        let frameCount = AVAudioFrameCount(audioFile.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw NSError(domain: "BayanCatalog", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to allocate audio buffer"])
        }

        try audioFile.read(into: buffer)
        try signatureGenerator.append(buffer, at: nil)

        let signature = signatureGenerator.signature()

        // Build ShazamKit Media Item with Quran Metadata
        let mediaItem = SHMediaItem(properties: [
            .title: reference.surahNameEnglish,
            .subtitle: reference.surahNameArabic,
            .artist: reference.reciterName,
            .webURL: URL(string: "https://quran.com/\(reference.surahId)")!
        ])

        try customCatalog.addReferenceSignature(signature, representing: [mediaItem])
        print("✅ Added \(reference.surahNameEnglish) to catalog.")
    }

    func exportCatalog(to destinationUrl: URL) throws {
        print("💾 Exporting Bayan.shazamcatalog to: \(destinationUrl.path)...")
        try customCatalog.write(to: destinationUrl)
        print("🎉 Successfully generated Bayan.shazamcatalog!")
    }
}

// MARK: - CLI Runner
@available(macOS 12.0, iOS 15.0, *)
func main() async {
    print("==========================================")
    print("  BAYAN (بَيَان) - Quran Shazam Catalog Builder")
    print("==========================================")

    let builder = QuranCatalogBuilder()
    let outputCatalogUrl = URL(fileURLWithPath: "BayanQuran.shazamcatalog")

    // The script can process local audio files or files downloaded from EveryAyah:
    // e.g. "https://everyayah.com/data/Alafasy_128kbps/001001.mp3"
    print("Ready to index recitations. Place your reference audio files in './reference_audio/' and execute.")
}
