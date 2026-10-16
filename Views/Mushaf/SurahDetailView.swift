import SwiftUI

struct SurahDetailView: View {
    let surah: Surah
    var initialAyah: Int = 1

    @State private var playerService = AudioPlayerService.shared
    @State private var syncManager = QuranSyncManager.shared
    @State private var activeAyah: Int = 1
    @State private var showingReciterSheet = false

    var body: some View {
        ZStack {
            BayanTheme.obsidian.ignoresSafeArea()
            RadialGradient(
                colors: [BayanTheme.deepEmerald.opacity(0.4), Color.clear],
                center: .top,
                startRadius: 50,
                endRadius: 500
            )
            .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        // Surah Header Banner
                        VStack(spacing: 12) {
                            Text(surah.nameArabic)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)

                            Text("\(surah.nameEnglish) • \(surah.nameTranslation)")
                                .font(.subheadline)
                                .foregroundColor(BayanTheme.goldSoft)

                            HStack(spacing: 12) {
                                Label("\(surah.totalAyahs) Ayahs", systemImage: "text.alignleft")
                                Text("•")
                                Label(surah.revelationType.arabicTitle, systemImage: "building.columns.fill")
                                Text("•")
                                Label("Page \(surah.startPage)", systemImage: "book.pages")
                            }
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .liquidGlass(isGoldBorder: true)
                        .padding(.horizontal)

                        // Bismillah (except Surah At-Tawbah #9)
                        if surah.id != 9 && surah.id != 1 {
                            Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ")
                                .font(.system(size: 26, weight: .medium, design: .serif))
                                .foregroundColor(BayanTheme.goldSoft)
                                .padding(.vertical, 8)
                        }

                        // All Ayahs in Surah
                        LazyVStack(spacing: 16) {
                            ForEach(1...surah.totalAyahs, id: \.self) { ayahNum in
                                AyahRow(
                                    surah: surah,
                                    ayahNumber: ayahNum,
                                    isActive: activeAyah == ayahNum && playerService.isPlaying
                                ) {
                                    activeAyah = ayahNum
                                    playerService.play(surah: surah, ayah: ayahNum)
                                }
                                .id(ayahNum)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 120) // Space for floating audio player
                    }
                    .padding(.top, 16)
                }
                .onAppear {
                    activeAyah = initialAyah
                    proxy.scrollTo(initialAyah, anchor: .center)
                    syncManager.updateLastRead(
                        surahId: surah.id,
                        ayahId: initialAyah,
                        page: surah.startPage,
                        qariId: playerService.currentReciter.id
                    )
                }
            }

            // Bottom Floating Liquid Glass Audio Player
            VStack {
                Spacer()
                FloatingPlayerBar(
                    surah: surah,
                    activeAyah: activeAyah,
                    onOpenReciterPicker: { showingReciterSheet = true }
                )
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    syncManager.toggleFavorite(surahId: surah.id)
                } label: {
                    Image(systemName: syncManager.favoriteSurahIds.contains(surah.id) ? "heart.fill" : "heart")
                        .foregroundColor(BayanTheme.gold)
                }
            }
        }
        .sheet(isPresented: $showingReciterSheet) {
            ReciterPickerSheet(selectedReciter: $playerService.currentReciter)
                .presentationDetents([.medium, .large])
        }
    }
}

// Single Ayah Row
private struct AyahRow: View {
    let surah: Surah
    let ayahNumber: Int
    let isActive: Bool
    let onPlayTap: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 14) {
            HStack {
                Button(action: onPlayTap) {
                    Image(systemName: isActive ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(isActive ? BayanTheme.gold : .white.opacity(0.6))
                }

                Spacer()

                // Ayah Medallion
                ZStack {
                    Circle()
                        .stroke(BayanTheme.gold.opacity(0.4), lineWidth: 1)
                        .frame(width: 30, height: 30)
                    Text("\(ayahNumber)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(BayanTheme.goldSoft)
                }
            }

            // Arabic Verse (Sample representation)
            Text(sampleArabicAyah(ayahNumber: ayahNumber))
                .font(.system(size: 24, weight: .regular, design: .serif))
                .multilineTextAlignment(.trailing)
                .lineSpacing(10)
                .foregroundColor(isActive ? BayanTheme.goldSoft : .white)

            // English Translation
            Text(sampleEnglishAyah(ayahNumber: ayahNumber))
                .font(.callout)
                .foregroundColor(.white.opacity(0.75))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .liquidGlass(cornerRadius: 20, isGoldBorder: isActive)
    }

    private func sampleArabicAyah(ayahNumber: Int) -> String {
        switch ayahNumber {
        case 1: return "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ"
        case 2: return "ٱلرَّحْمَٰنِ ٱلرَّحِيمِ"
        case 3: return "مَٰلِكِ يَوْمِ ٱلدِّينِ"
        case 4: return "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ"
        case 5: return "ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ"
        default: return "صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ"
        }
    }

    private func sampleEnglishAyah(ayahNumber: Int) -> String {
        switch ayahNumber {
        case 1: return "[All] praise is [due] to Allah, Lord of the worlds."
        case 2: return "The Entirely Merciful, the Especially Merciful."
        case 3: return "Sovereign of the Day of Recompense."
        case 4: return "It is You we worship and You we ask for help."
        case 5: return "Guide us to the straight path."
        default: return "The path of those upon whom You have bestowed favor, not of those who have evoked [Your] anger or of those who are astray."
        }
    }
}

// Floating Player Bar
private struct FloatingPlayerBar: View {
    let surah: Surah
    let activeAyah: Int
    var onOpenReciterPicker: () -> Void

    @State private var playerService = AudioPlayerService.shared

    var body: some View {
        HStack(spacing: 16) {
            // Reciter Avatar Button
            Button(action: onOpenReciterPicker) {
                HStack(spacing: 8) {
                    Image(systemName: "person.wave.2.fill")
                        .foregroundColor(BayanTheme.gold)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(playerService.currentReciter.nameEnglish)
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text("Tap to change")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Play / Pause Button
            Button {
                playerService.togglePlayPause()
            } label: {
                Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
                    .foregroundColor(BayanTheme.obsidian)
                    .frame(width: 44, height: 44)
                    .background(BayanTheme.gold)
                    .clipShape(Circle())
                    .shadow(color: BayanTheme.gold.opacity(0.4), radius: 8, y: 3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .liquidGlass(cornerRadius: 24, isGoldBorder: true)
    }
}
