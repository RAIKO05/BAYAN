import Foundation
import SwiftUI

// MARK: - Decodable AlQuran.cloud API Response
private struct AlQuranCloudSurahResponse: Codable {
    let code: Int
    let status: String
    let data: AlQuranCloudSurahData
}

private struct AlQuranCloudSurahData: Codable {
    let number: Int
    let name: String
    let englishName: String
    let ayahs: [AlQuranCloudAyahData]
}

private struct AlQuranCloudAyahData: Codable {
    let numberInSurah: Int
    let text: String
}

// MARK: - Multi-Language Quran Translation Service
@Observable
public final class QuranTranslationService {
    public static let shared = QuranTranslationService()

    private let kSelectedTranslationLang = "bayan_selected_translation_lang"

    public var selectedLanguage: QuranTranslationLanguage = .english {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: kSelectedTranslationLang)
        }
    }

    // Dynamic in-memory cache: key is "{lang}_{surahId}", value is [ayahNumber: text]
    private var inMemoryCache: [String: [Int: String]] = [:]
    private var inFlightRequests: Set<String> = []

    private init() {
        if let stored = UserDefaults.standard.string(forKey: kSelectedTranslationLang),
           let lang = QuranTranslationLanguage(rawValue: stored) {
            self.selectedLanguage = lang
        }
        loadBundledTranslations()
    }

    // MARK: - Bundled Offline Cache Loader
    private func loadBundledTranslations() {
        guard let url = Bundle.main.url(forResource: "quran_multi_translations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let jsonMap = try? JSONDecoder().decode([String: [String: String]].self, from: data) else {
            return
        }

        for (key, ayahs) in jsonMap {
            var intMap: [Int: String] = [:]
            for (ayahStr, text) in ayahs {
                if let num = Int(ayahStr) {
                    intMap[num] = text
                }
            }
            inMemoryCache[key] = intMap
        }
    }

    // MARK: - Translation Retrieval API
    public func translation(for surahId: Int, ayahNumber: Int, language: QuranTranslationLanguage? = nil) -> String {
        let activeLang = language ?? selectedLanguage

        switch activeLang {
        case .english:
            return QuranVerseText.translation(surahId: surahId, ayahNumber: ayahNumber)

        case .arabicTafsir:
            return QuranTafsirService.shared.tafsir(for: surahId, ayahNumber: ayahNumber).arabicTafsir

        case .french, .spanish, .turkish, .indonesian, .urdu:
            let cacheKey = "\(activeLang.rawValue)_\(surahId)"
            if let surahAyahs = inMemoryCache[cacheKey], let text = surahAyahs[ayahNumber], !text.isEmpty {
                return text
            }

            // Check persistent disk cache
            if let diskAyahs = loadFromDisk(cacheKey: cacheKey) {
                inMemoryCache[cacheKey] = diskAyahs
                if let text = diskAyahs[ayahNumber], !text.isEmpty {
                    return text
                }
            }

            // Trigger background network fetch if missing
            fetchSurahTranslations(surahId: surahId, language: activeLang)

            // Temporary English fallback while network loads in ~100ms
            return QuranVerseText.translation(surahId: surahId, ayahNumber: ayahNumber)
        }
    }

    // MARK: - Proactive Preloading
    public func ensureSurahLoaded(surahId: Int, language: QuranTranslationLanguage) {
        guard language != .english && language != .arabicTafsir else { return }
        let cacheKey = "\(language.rawValue)_\(surahId)"
        guard inMemoryCache[cacheKey] == nil else { return }
        fetchSurahTranslations(surahId: surahId, language: language)
    }

    private func editionIdentifier(for language: QuranTranslationLanguage) -> String? {
        switch language {
        case .french: return "fr.hamidullah"
        case .spanish: return "es.cortes"
        case .turkish: return "tr.diyanet"
        case .indonesian: return "id.indonesian"
        case .urdu: return "ur.jalandhry"
        default: return nil
        }
    }

    private func fetchSurahTranslations(surahId: Int, language: QuranTranslationLanguage) {
        guard let edition = editionIdentifier(for: language) else { return }
        let cacheKey = "\(language.rawValue)_\(surahId)"
        guard !inFlightRequests.contains(cacheKey) else { return }

        inFlightRequests.insert(cacheKey)
        let urlString = "https://api.alquran.cloud/v1/surah/\(surahId)/\(edition)"
        guard let url = URL(string: urlString) else {
            inFlightRequests.remove(cacheKey)
            return
        }

        var req = URLRequest(url: url)
        req.timeoutInterval = 8.0
        req.setValue("BayanApp/1.0", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: req) { [weak self] data, _, error in
            guard let self = self else { return }
            defer {
                DispatchQueue.main.async {
                    self.inFlightRequests.remove(cacheKey)
                }
            }

            guard let data = data, error == nil else { return }
            if let root = try? JSONDecoder().decode(AlQuranCloudSurahResponse.self, from: data) {
                var map: [Int: String] = [:]
                for ayah in root.data.ayahs {
                    map[ayah.numberInSurah] = ayah.text
                }
                DispatchQueue.main.async {
                    self.inMemoryCache[cacheKey] = map
                    self.saveToDisk(cacheKey: cacheKey, map: map)
                }
            }
        }.resume()
    }

    // MARK: - Disk Persistence Helpers
    private var cacheDirectory: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("BayanTranslationsCache", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(
                at: dir,
                withIntermediateDirectories: true,
                attributes: [FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
            )
            BayanSecurityManager.shared.excludeFromBackup(url: dir)
        }
        return dir
    }

    private func saveToDisk(cacheKey: String, map: [Int: String]) {
        let stringKeyMap = Dictionary(uniqueKeysWithValues: map.map { (String($0.key), $0.value) })
        let fileUrl = cacheDirectory.appendingPathComponent("\(cacheKey).json")
        if let data = try? JSONEncoder().encode(stringKeyMap) {
            try? data.write(to: fileUrl)
        }
    }

    private func loadFromDisk(cacheKey: String) -> [Int: String]? {
        let fileUrl = cacheDirectory.appendingPathComponent("\(cacheKey).json")
        guard let data = try? Data(contentsOf: fileUrl),
              let stringKeyMap = try? JSONDecoder().decode([String: String].self, from: data) else {
            return nil
        }

        var result: [Int: String] = [:]
        for (k, v) in stringKeyMap {
            if let num = Int(k) {
                result[num] = v
            }
        }
        return result
    }
}
