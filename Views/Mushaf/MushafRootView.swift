import SwiftUI

struct MushafRootView: View {
    @State private var syncManager = QuranSyncManager.shared
    @State private var dataService = QuranDataService.shared
    @State private var playerService = AudioPlayerService.shared

    @State private var searchQuery = ""
    @State private var selectedFilter: FilterCategory = .all
    @State private var showingReciterPicker = false
    @State private var navigateToSurah: Surah?
    @State private var navigateToAyah: Int = 1

    enum FilterCategory: String, CaseIterable {
        case all = "All"
        case meccan = "Meccan"
        case medinan = "Medinan"
        case favorites = "Favorites"
    }

    private var filteredSurahs: [Surah] {
        let base = dataService.search(query: searchQuery)
        switch selectedFilter {
        case .all:
            return base
        case .meccan:
            return base.filter { $0.revelationType == .meccan }
        case .medinan:
            return base.filter { $0.revelationType == .medinan }
        case .favorites:
            return base.filter { syncManager.favoriteSurahIds.contains($0.id) }
        }
    }

    private var lastReadSurah: Surah? {
        dataService.surah(for: syncManager.lastSurahId)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                BayanTheme.obsidian.ignoresSafeArea()
                RadialGradient(
                    colors: [BayanTheme.deepEmerald.opacity(0.35), Color.clear],
                    center: .topLeading,
                    startRadius: 50,
                    endRadius: 500
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // "Where I Stopped" Resume Banner
                        if let lastSurah = lastReadSurah {
                            ResumeReadingCard(
                                surah: lastSurah,
                                ayahNumber: syncManager.lastAyahId,
                                page: syncManager.lastPageNumber
                            ) {
                                self.navigateToSurah = lastSurah
                                self.navigateToAyah = syncManager.lastAyahId
                            }
                            .padding(.horizontal)
                        }

                        // Active Reciter Quick Selector
                        Button {
                            showingReciterPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "person.wave.2.fill")
                                    .foregroundColor(BayanTheme.gold)
                                Text(playerService.currentReciter.nameEnglish)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("Change Qari")
                                    .font(.caption)
                                    .foregroundColor(BayanTheme.goldSoft)
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .liquidGlass(cornerRadius: 18)
                            .padding(.horizontal)
                        }

                        // Filter Chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(FilterCategory.allCases, id: \.self) { category in
                                    Button {
                                        selectedFilter = category
                                    } label: {
                                        Text(category.rawValue)
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(selectedFilter == category ? BayanTheme.gold : Color.white.opacity(0.08))
                                            .foregroundColor(selectedFilter == category ? BayanTheme.obsidian : .white)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule().stroke(selectedFilter == category ? Color.clear : Color.white.opacity(0.12), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Surah List
                        LazyVStack(spacing: 12) {
                            ForEach(filteredSurahs) { surah in
                                NavigationLink {
                                    SurahDetailView(surah: surah, initialAyah: 1)
                                } label: {
                                    SurahListRow(surah: surah)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Holy Qur'an")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchQuery, prompt: "Search 114 Surahs...")
            .sheet(isPresented: $showingReciterPicker) {
                ReciterPickerSheet(selectedReciter: $playerService.currentReciter)
                    .presentationDetents([.medium, .large])
            }
            .navigationDestination(item: $navigateToSurah) { surah in
                SurahDetailView(surah: surah, initialAyah: navigateToAyah)
            }
        }
    }
}

// Surah List Row Item
private struct SurahListRow: View {
    let surah: Surah

    var body: some View {
        HStack(spacing: 14) {
            // Surah Number Medallion
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 44, height: 44)
                Text("\(surah.id)")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(BayanTheme.goldSoft)
            }

            // English & Translation
            VStack(alignment: .leading, spacing: 3) {
                Text(surah.nameEnglish)
                    .font(.headline)
                    .foregroundColor(.white)

                Text("\(surah.nameTranslation) • \(surah.totalAyahs) Ayahs")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.65))
            }

            Spacer()

            // Arabic Calligraphy & Revelation Badge
            VStack(alignment: .trailing, spacing: 4) {
                Text(surah.nameArabic)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(BayanTheme.goldSoft)

                Text(surah.revelationType.arabicTitle)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.08))
                    .foregroundColor(.white.opacity(0.7))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .liquidGlass(cornerRadius: 20)
    }
}
