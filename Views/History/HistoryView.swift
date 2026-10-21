import SwiftUI

struct HistoryView: View {
    @State private var syncManager = QuranSyncManager.shared
    @State private var playerService = AudioPlayerService.shared
    @State private var bookmarkService = BookmarkService.shared
    @State private var themeManager = AppThemeManager.shared
    @State private var selectedTab: Int = 0
    @State private var selectedTafsirSurah: Surah? = nil
    @State private var selectedTafsirAyah: Int = 1

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                themeManager.currentTheme.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Segmented Filter Bar: Recitations vs Bookmarks
                    Picker("History View", selection: $selectedTab) {
                        Text("Recitations (\(syncManager.recentRecognitions.count))").tag(0)
                        Text("Bookmarks (\(bookmarkService.bookmarks.count))").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                    if selectedTab == 0 {
                        // MARK: - Recitations Tab
                        if syncManager.recentRecognitions.isEmpty {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "clock.badge.questionmark")
                                    .font(.system(size: 64))
                                    .foregroundColor(BayanTheme.gold.opacity(0.5))

                                Text("No Recognitions Yet")
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(.white)

                                Text("Recitations you identify in the Listen tab will be automatically saved here for quick review.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            Spacer()
                        } else {
                            List {
                                ForEach(syncManager.recentRecognitions) { item in
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack {
                                            Text(item.surah.nameArabic)
                                                .font(.title3.weight(.bold))
                                                .foregroundColor(BayanTheme.goldSoft)

                                            Spacer()

                                            Text(item.recognizedAt, format: .dateTime.month().day().hour().minute())
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }

                                        Text("\(item.surah.nameEnglish) • Ayah \(item.startAyah)–\(item.endAyah)")
                                            .font(.headline)
                                            .foregroundColor(.white)

                                        HStack(spacing: 8) {
                                            Image(systemName: "person.wave.2.fill")
                                                .foregroundColor(BayanTheme.gold)
                                            Text(item.reciter.nameEnglish)
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.8))
                                        }

                                        Text(item.arabicSnippet)
                                            .font(.system(size: 16, design: .serif))
                                            .foregroundColor(.white.opacity(0.9))
                                            .lineLimit(2)
                                            .frame(maxWidth: .infinity, alignment: .trailing)

                                        // Quick Play & Tafsir Actions
                                        let isThisItemPlaying = playerService.isPlaying && playerService.currentSurah?.id == item.surah.id
                                        HStack(spacing: 10) {
                                            Button {
                                                if isThisItemPlaying {
                                                    playerService.togglePlayPause()
                                                } else {
                                                    playerService.play(
                                                        surah: item.surah,
                                                        ayah: item.startAyah,
                                                        reciter: item.reciter
                                                    )
                                                }
                                            } label: {
                                                HStack {
                                                    Image(systemName: isThisItemPlaying ? "pause.fill" : "play.fill")
                                                    Text(isThisItemPlaying ? "Pause" : "Play Recitation")
                                                }
                                                .font(.caption.weight(.bold))
                                                .foregroundColor(BayanTheme.obsidian)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 7)
                                                .background(BayanTheme.gold)
                                                .clipShape(Capsule())
                                            }

                                            Button {
                                                selectedTafsirAyah = item.startAyah
                                                selectedTafsirSurah = item.surah
                                                #if os(iOS)
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                #endif
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "book.pages")
                                                    Text("Tafsir")
                                                }
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(BayanTheme.goldSoft)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 7)
                                                .background(Color.white.opacity(0.08))
                                                .clipShape(Capsule())
                                            }
                                        }
                                        .padding(.top, 4)
                                    }
                                    .padding(16)
                                    .liquidGlass(cornerRadius: 18)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                }
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 120) }
                        }
                    } else {
                        // MARK: - Bookmarks Tab
                        if bookmarkService.bookmarks.isEmpty {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "bookmark.slash")
                                    .font(.system(size: 64))
                                    .foregroundColor(BayanTheme.gold.opacity(0.5))

                                Text("No Bookmarks Saved")
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(.white)

                                Text("Tap the bookmark icon on any identified Ayah or in the Mushaf reader to save your favorite verses here.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            Spacer()
                        } else {
                            List {
                                ForEach(bookmarkService.bookmarks) { bookmark in
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack {
                                            Text(bookmark.surahNameArabic)
                                                .font(.title3.weight(.bold))
                                                .foregroundColor(BayanTheme.goldSoft)

                                            Spacer()

                                            // Delete / Remove Bookmark Button
                                            Button {
                                                #if os(iOS)
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                #endif
                                                bookmarkService.removeBookmark(id: bookmark.id)
                                            } label: {
                                                Image(systemName: "trash")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.white.opacity(0.45))
                                                    .padding(6)
                                                    .background(Circle().fill(Color.white.opacity(0.06)))
                                            }
                                            .buttonStyle(.plain)
                                        }

                                        HStack(spacing: 6) {
                                            Text("\(bookmark.surahNameEnglish)")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text("• Ayah \(bookmark.ayahNumber)")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(BayanTheme.electricCyan)
                                        }

                                        Text(bookmark.arabicText)
                                            .font(.system(size: 17, design: .serif))
                                            .foregroundColor(.white.opacity(0.95))
                                            .multilineTextAlignment(.trailing)
                                            .frame(maxWidth: .infinity, alignment: .trailing)

                                        if !bookmark.translationText.isEmpty {
                                            Text(bookmark.translationText)
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.7))
                                                .lineLimit(3)
                                        }

                                        // Play Recitation & Tafsir Buttons
                                        if let surah = QuranDataService.shared.surah(for: bookmark.surahId) {
                                            let isThisPlaying = playerService.isPlaying && playerService.currentSurah?.id == bookmark.surahId && playerService.currentAyah == bookmark.ayahNumber
                                            HStack(spacing: 10) {
                                                Button {
                                                    if isThisPlaying {
                                                        playerService.togglePlayPause()
                                                    } else {
                                                        playerService.play(surah: surah, ayah: bookmark.ayahNumber)
                                                    }
                                                } label: {
                                                    HStack {
                                                        Image(systemName: isThisPlaying ? "pause.fill" : "play.fill")
                                                        Text(isThisPlaying ? "Pause" : "Play Recitation")
                                                    }
                                                    .font(.caption.weight(.bold))
                                                    .foregroundColor(BayanTheme.obsidian)
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 7)
                                                    .background(BayanTheme.gold)
                                                    .clipShape(Capsule())
                                                }

                                                Button {
                                                    selectedTafsirAyah = bookmark.ayahNumber
                                                    selectedTafsirSurah = surah
                                                    #if os(iOS)
                                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                    #endif
                                                } label: {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "book.pages")
                                                        Text("Tafsir")
                                                    }
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundColor(BayanTheme.goldSoft)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 7)
                                                    .background(Color.white.opacity(0.08))
                                                    .clipShape(Capsule())
                                                }
                                            }
                                            .padding(.top, 4)
                                        }
                                    }
                                    .padding(16)
                                    .liquidGlass(cornerRadius: 18, isGoldBorder: true)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                }
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 120) }
                        }
                    }
                }
            }
            .navigationTitle(selectedTab == 0 ? "Recognized History" : "Saved Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedTafsirSurah) { surah in
                AyahTafsirSheet(surah: surah, ayahNumber: selectedTafsirAyah)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}
