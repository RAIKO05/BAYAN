import Foundation

// MARK: - Bookmark Service
// Manages saved/favorite Ayahs across the Bayan app with local persistence
@Observable
public final class BookmarkService {
    public static let shared = BookmarkService()

    public var bookmarks: [AyahBookmark] = []
    private let storageKey = "bayan_ayah_bookmarks"

    private init() {
        loadBookmarks()
    }

    public func isBookmarked(surahId: Int, ayahNumber: Int) -> Bool {
        bookmarks.contains { $0.surahId == surahId && $0.ayahNumber == ayahNumber }
    }

    @discardableResult
    public func toggleBookmark(
        surahId: Int,
        ayahNumber: Int,
        surahNameArabic: String,
        surahNameEnglish: String,
        arabicText: String,
        translationText: String
    ) -> Bool {
        if let index = bookmarks.firstIndex(where: { $0.surahId == surahId && $0.ayahNumber == ayahNumber }) {
            bookmarks.remove(at: index)
            saveBookmarks()
            return false
        } else {
            let newBookmark = AyahBookmark(
                surahId: surahId,
                ayahNumber: ayahNumber,
                surahNameArabic: surahNameArabic,
                surahNameEnglish: surahNameEnglish,
                arabicText: arabicText,
                translationText: translationText
            )
            bookmarks.insert(newBookmark, at: 0)
            saveBookmarks()
            return true
        }
    }

    public func removeBookmark(id: UUID) {
        bookmarks.removeAll { $0.id == id }
        saveBookmarks()
    }

    private func saveBookmarks() {
        if let encoded = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
            BayanCloudSyncService.shared.pushLocalChanges()
        }
    }

    private func loadBookmarks() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([AyahBookmark].self, from: data) {
            self.bookmarks = decoded
        }
    }
}
