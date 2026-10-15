import SwiftUI
import Combine

@Observable
public final class QuranSyncManager {
    public static let shared = QuranSyncManager()

    // Persistent Last Read Position
    @ObservationIgnored
    @AppStorage("bayan_last_surah_id") public var lastSurahId: Int = 18 // Defaults to Surah Al-Kahf
    
    @ObservationIgnored
    @AppStorage("bayan_last_ayah_id") public var lastAyahId: Int = 1
    
    @ObservationIgnored
    @AppStorage("bayan_last_page_number") public var lastPageNumber: Int = 293
    
    @ObservationIgnored
    @AppStorage("bayan_last_qari_id") public var lastQariId: String = "alafasy"
    
    @ObservationIgnored
    @AppStorage("bayan_last_audio_timestamp") public var lastAudioTimestamp: Double = 0.0

    // History & Favorites
    public var recentRecognitions: [RecognitionResult] = []
    public var favoriteSurahIds: Set<Int> = [1, 18, 36, 55, 67]

    private let historyStorageKey = "bayan_recognition_history"

    public init() {
        loadHistory()
    }

    public func updateLastRead(surahId: Int, ayahId: Int, page: Int, qariId: String, audioTime: Double = 0.0) {
        self.lastSurahId = surahId
        self.lastAyahId = ayahId
        self.lastPageNumber = page
        self.lastQariId = qariId
        self.lastAudioTimestamp = audioTime
    }

    public func addRecognition(_ result: RecognitionResult) {
        recentRecognitions.insert(result, at: 0)
        saveHistory()
    }

    public func toggleFavorite(surahId: Int) {
        if favoriteSurahIds.contains(surahId) {
            favoriteSurahIds.remove(surahId)
        } else {
            favoriteSurahIds.insert(surahId)
        }
    }

    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(recentRecognitions) {
            UserDefaults.standard.set(encoded, forKey: historyStorageKey)
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyStorageKey),
           let decoded = try? JSONDecoder().decode([RecognitionResult].self, from: data) {
            self.recentRecognitions = decoded
        } else {
            // Pre-fill with a sample recognition
            self.recentRecognitions = [RecognitionResult.sample]
        }
    }
}
