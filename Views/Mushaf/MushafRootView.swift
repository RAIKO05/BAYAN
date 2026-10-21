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

                VStack(spacing: 0) {
                    // MARK: - Pinned Header (Title, Qira'at Toggle & Always-Visible Search Bar)
                    VStack(spacing: 12) {
                        // Title & Qira'at Switcher Row
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("HOLY QUR'AN")
                                    .font(.system(size: 10.5, weight: .bold))
                                    .tracking(2.0)
                                    .foregroundColor(BayanTheme.gold.opacity(0.9))

                                Text("المصحف الشريف")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            Spacer()

                            // Qira'at Pill Switcher: Hafs vs Warsh
                            HStack(spacing: 2) {
                                ForEach(QuranDataService.Qiraah.allCases) { qiraah in
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
                                            .background(
                                                dataService.selectedQiraah == qiraah ?
                                                    BayanTheme.gold :
                                                    Color.clear
                                            )
                                            .foregroundColor(
                                                dataService.selectedQiraah == qiraah ?
                                                    BayanTheme.obsidian :
                                                    .white.opacity(0.7)
                                            )
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
                        .padding(.horizontal, 18)
                        .padding(.top, 4)

                        // MARK: - Dedicated Custom Search Bar (Always Accessible)
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

                        // MARK: - Category Filter Chips
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
                    .padding(.bottom, 10)
                    .background(
                        BayanTheme.obsidian.opacity(0.85)
                            .background(.ultraThinMaterial)
                    )
                    .overlay(
                        Divider().overlay(Color.white.opacity(0.08)),
                        alignment: .bottom
                    )

                    // MARK: - Scrollable Surah Content
                    ScrollView {
                        VStack(spacing: 16) {
                            // Show "Resume" and "Change Qari" when not searching
                            if searchQuery.isEmpty {
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
                                    .padding(.horizontal, 18)
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
                                    .padding(.horizontal, 18)
                                }
                            } else {
                                // Search Result Status Badge
                                HStack {
                                    Text("FOUND \(filteredSurahs.count) SURAHS")
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(1.5)
                                        .foregroundColor(BayanTheme.goldSoft)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 4)
                            }

                            // Empty State
                            if filteredSurahs.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.system(size: 48))
                                        .foregroundColor(BayanTheme.gold.opacity(0.4))
                                        .padding(.top, 40)

                                    Text("No Surahs Found")
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    Text("No Surahs matched \"\(searchQuery)\". Check the spelling or search by number (1–114).")
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
                            } else {
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
                                .padding(.horizontal, 18)
                            }
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                    }
                    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 120) }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarHidden(true)
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
