import SwiftUI

struct MushafRootView: View {
    @State private var syncManager = QuranSyncManager.shared
    @State private var dataService = QuranDataService.shared
    @State private var playerService = AudioPlayerService.shared

    @State private var searchQuery = ""
    @State private var selectedFilter: FilterCategory = .all
    @State private var showingReciterPicker = false
    @State private var showingThemeSheet = false
    @State private var navigateToSurah: Surah?
    @State private var navigateToAyah: Int = 1
    @State private var themeManager = AppThemeManager.shared

    enum SearchTarget: String, CaseIterable {
        case surahs = "Surahs"
        case verses = "Verses"
    }

    @State private var searchTarget: SearchTarget = .surahs
    @State private var searchedVerses: [VerseSearchResult] = []
    @State private var isSearchingVerses: Bool = false
    @State private var verseSearchTask: Task<Void, Never>? = nil

    private var currentTheme: QuranTheme {
        themeManager.currentTheme
    }

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
                backgroundGradient

                VStack(spacing: 0) {
                    pinnedHeaderView
                    scrollableContent
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingReciterPicker) {
                ReciterPickerSheet(selectedReciter: $playerService.currentReciter)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingThemeSheet) {
                VStack(spacing: 20) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 36, height: 5)
                        .padding(.top, 12)

                    QuranThemeSelectorCard(selectedTheme: Binding(
                        get: { themeManager.currentTheme },
                        set: { themeManager.setTheme($0) }
                    ))
                    .padding(.horizontal, 16)

                    Spacer()
                }
                .background(currentTheme.backgroundColor.ignoresSafeArea())
                .presentationDetents([.fraction(0.42), .medium])
            }
            .navigationDestination(item: $navigateToSurah) { surah in
                SurahDetailView(surah: surah, initialAyah: navigateToAyah)
            }
            .onChange(of: searchQuery) { _, newValue in
                triggerVerseSearch(query: newValue)
            }
            .onChange(of: searchTarget) { _, newTarget in
                if newTarget == .verses && searchedVerses.isEmpty && !searchQuery.isEmpty {
                    triggerVerseSearch(query: searchQuery)
                }
            }
        }
    }

    private func triggerVerseSearch(query: String) {
        verseSearchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard searchTarget == .verses && trimmed.count >= 2 else {
            searchedVerses = []
            isSearchingVerses = false
            return
        }

        isSearchingVerses = true
        verseSearchTask = Task {
            try? await Task.sleep(nanoseconds: 160_000_000)
            if Task.isCancelled { return }

            let matches = await Task.detached(priority: .userInitiated) {
                return QuranVerseText.searchAllVerses(query: trimmed, limit: 60)
            }.value

            if !Task.isCancelled {
                self.searchedVerses = matches
                self.isSearchingVerses = false
            }
        }
    }

    // MARK: - Background Layer
    private var backgroundGradient: some View {
        ZStack {
            currentTheme.backgroundColor.ignoresSafeArea()
            currentTheme.backgroundGradient.ignoresSafeArea()
        }
    }

    // MARK: - Pinned Header
    private var pinnedHeaderView: some View {
        VStack(spacing: 12) {
            titleAndQiraahRow
            searchBarField
            if !searchQuery.isEmpty {
                searchTargetSelectorRow
            } else {
                filterChipsRow
            }
        }
        .padding(.bottom, 10)
        .background(
            currentTheme.backgroundColor.opacity(0.85)
                .background(.ultraThinMaterial)
        )
        .overlay(
            Divider().overlay(currentTheme.cardBorder),
            alignment: .bottom
        )
    }

    // MARK: - Title & Qira'at Row
    private var titleAndQiraahRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("HOLY QUR'AN")
                    .font(.system(size: 10.5, weight: .bold))
                    .tracking(2.0)
                    .foregroundColor(currentTheme.headerSubtitleColor)

                Text("المصحف الشريف")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(currentTheme.headerTitleColor)
            }

            Spacer()

            HStack(spacing: 8) {
                qiraahTogglePill

                Button {
                    showingThemeSheet = true
                } label: {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 13, weight: .medium))
                        .padding(8)
                        .background(currentTheme.isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                        .foregroundColor(currentTheme.toolbarAccentColor)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(currentTheme.cardBorder, lineWidth: 1))
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 4)
    }

    // MARK: - Qira'at Pill Toggle
    private var qiraahTogglePill: some View {
        HStack(spacing: 2) {
            ForEach(QuranDataService.Qiraah.allCases) { qiraah in
                let isSelected = dataService.selectedQiraah == qiraah
                Button {
                    dataService.selectedQiraah = qiraah
                    if qiraah == .warsh {
                        if let warshReciter = Reciter.standardCatalog.first(where: { $0.id == "yassin_warsh" }) ?? Reciter.standardCatalog.first(where: { $0.id == "kazabri_warsh" }) {
                            playerService.currentReciter = warshReciter
                        }
                    } else {
                        if let hafsReciter = Reciter.standardCatalog.first(where: { $0.id == "alafasy" }) {
                            playerService.currentReciter = hafsReciter
                        }
                    }
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    Text(qiraah.shortLabel)
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(isSelected ? BayanTheme.gold : Color.clear)
                        .foregroundColor(isSelected ? BayanTheme.obsidian : .white.opacity(0.7))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
    }

    // MARK: - Dedicated Search Bar Field
    private var searchBarField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(searchQuery.isEmpty ? .white.opacity(0.4) : BayanTheme.gold)

            TextField("Search Surah name or number (e.g. 18, Kahf, كهف)...", text: $searchQuery)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.55))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(searchQuery.isEmpty ? Color.white.opacity(0.12) : BayanTheme.gold.opacity(0.5), lineWidth: 1)
        )
        .padding(.horizontal, 18)
    }

    // MARK: - Search Target Segmented Control (Surahs vs Full-Text Verses)
    private var searchTargetSelectorRow: some View {
        HStack(spacing: 8) {
            ForEach(SearchTarget.allCases, id: \.self) { target in
                let isSelected = searchTarget == target
                let count = target == .surahs ? filteredSurahs.count : searchedVerses.count
                Button {
                    searchTarget = target
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: target == .surahs ? "book.closed.fill" : "text.quote")
                            .font(.system(size: 11))
                        Text("\(target.rawValue) (\(count))")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(isSelected ? BayanTheme.gold : Color.white.opacity(0.08))
                    .foregroundColor(isSelected ? BayanTheme.obsidian : .white)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(isSelected ? Color.clear : Color.white.opacity(0.12), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 18)
    }

    // MARK: - Filter Chips Row
    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FilterCategory.allCases, id: \.self) { category in
                    let isSelected = selectedFilter == category
                    Button {
                        selectedFilter = category
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        HStack(spacing: 4) {
                            Text(category.rawValue)
                            if category == .favorites && !syncManager.favoriteSurahIds.isEmpty {
                                Text("(\(syncManager.favoriteSurahIds.count))")
                                    .font(.system(size: 10, weight: .bold))
                            }
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(isSelected ? BayanTheme.gold : Color.white.opacity(0.06))
                        .foregroundColor(isSelected ? BayanTheme.obsidian : .white.opacity(0.85))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
        }
    }

    // MARK: - Scrollable Surahs & Verses Content
    private var scrollableContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                if searchQuery.isEmpty {
                    resumeAndReciterSection
                    surahListLazyVStack
                } else if searchTarget == .surahs {
                    HStack {
                        Text("FOUND \(filteredSurahs.count) SURAHS")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(BayanTheme.goldSoft)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    if filteredSurahs.isEmpty {
                        emptySearchResultsView
                    } else {
                        surahListLazyVStack
                    }
                } else {
                    HStack {
                        Text("FOUND \(searchedVerses.count) VERSES")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(BayanTheme.goldSoft)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    if searchedVerses.isEmpty {
                        emptyVerseResultsView
                    } else {
                        verseListLazyVStack
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 120) }
    }

    // MARK: - Resume Reading & Reciter Quick Selector
    @ViewBuilder
    private var resumeAndReciterSection: some View {
        // Personal Quran Completion / Khatmah Tracker Card
        KhatmahCardView { surah, ayah in
            self.navigateToSurah = surah
            self.navigateToAyah = ayah
        }
        .padding(.horizontal, 18)

        if let lastSurah = lastReadSurah {
            ResumeReadingCard(
                surah: lastSurah,
                ayahNumber: syncManager.lastAyahId,
                page: syncManager.lastPageNumber
            ) {
                self.navigateToSurah = lastSurah
                self.navigateToAyah = syncManager.lastAyahId
            }
            .padding(.horizontal, 18)
        }

        // Daily Quran Goal & Top Reciter Card (Replace Music With Quran)
        DailyQuranGoalCard {
            if let _ = playerService.currentSurah {
                if !playerService.isPlaying {
                    playerService.resume()
                }
            } else if let firstSurah = dataService.surah(for: 1) {
                playerService.play(surah: firstSurah, ayah: 1, reciter: playerService.currentReciter)
            }
        }
        .padding(.horizontal, 18)

        Button {
            showingReciterPicker = true
        } label: {
            HStack(spacing: 12) {
                ReciterAvatarView(reciter: playerService.currentReciter, size: 36, isSelected: true, borderWidth: 1.5)

                VStack(alignment: .leading, spacing: 2) {
                    Text(playerService.currentReciter.nameEnglish)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                    Text(playerService.currentReciter.nameArabic)
                        .font(.caption2)
                        .foregroundColor(BayanTheme.goldSoft)
                }

                Spacer()
                Text("Change Qari")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(BayanTheme.goldSoft)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .liquidGlass(cornerRadius: 18)
            .padding(.horizontal, 18)
        }
    }

    // MARK: - Empty Search State
    private var emptySearchResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(BayanTheme.gold.opacity(0.4))
                .padding(.top, 40)

            Text("No Surahs Found")
                .font(.headline)
                .foregroundColor(.white)

            Text("No Surahs matched \"\(searchQuery)\". Check spelling or search by number (1–114).")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Button("Clear Search") {
                searchQuery = ""
            }
            .font(.caption.weight(.bold))
            .foregroundColor(BayanTheme.obsidian)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(BayanTheme.gold)
            .clipShape(Capsule())
            .padding(.top, 8)
        }
    }

    // MARK: - Empty Verse Search State
    private var emptyVerseResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(BayanTheme.gold.opacity(0.4))
                .padding(.top, 40)

            Text("No Verses Found")
                .font(.headline)
                .foregroundColor(.white)

            Text("No Ayahs matched \"\(searchQuery)\". You can search in Arabic text or English translation.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Button("Clear Search") {
                searchQuery = ""
            }
            .font(.caption.weight(.bold))
            .foregroundColor(BayanTheme.obsidian)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(BayanTheme.gold)
            .clipShape(Capsule())
            .padding(.top, 8)
        }
    }

    // MARK: - Surah List
    private var surahListLazyVStack: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 330), spacing: 12)], spacing: 12) {
            ForEach(filteredSurahs) { surah in
                NavigationLink {
                    SurahDetailView(surah: surah, initialAyah: 1)
                } label: {
                    SurahListRow(surah: surah)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
    }

    // MARK: - Full-Text Verse Search Results List
    private var verseListLazyVStack: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 330), spacing: 12)], spacing: 12) {
            ForEach(searchedVerses) { result in
                Button {
                    if let surah = dataService.surah(for: result.surahId) {
                        navigateToAyah = result.ayahNumber
                        navigateToSurah = surah
                    }
                } label: {
                    VerseSearchRow(result: result, surah: dataService.surah(for: result.surahId))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
    }
}

// MARK: - Full-Text Verse Search Row Card
private struct VerseSearchRow: View {
    let result: VerseSearchResult
    let surah: Surah?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(surah?.nameEnglish ?? "Surah \(result.surahId)") • Ayah \(result.ayahNumber)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(BayanTheme.gold)

                Spacer()

                if let ar = surah?.nameArabic {
                    Text(ar)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(BayanTheme.goldSoft)
                }
            }

            Text(result.arabicText)
                .font(.system(size: 18, weight: .medium, design: .serif))
                .multilineTextAlignment(.trailing)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(.white)

            if !result.translationText.isEmpty {
                Text(result.translationText)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(3)
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18)
    }
}

// MARK: - Surah List Row Item
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
