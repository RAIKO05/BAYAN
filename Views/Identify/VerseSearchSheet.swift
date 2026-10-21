import SwiftUI

public struct VerseSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var themeManager = AppThemeManager.shared
    @State private var searchText = ""
    @State private var results: [VerseSearchResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>? = nil

    public var onSelect: (RecognitionResult) -> Void

    public init(onSelect: @escaping (RecognitionResult) -> Void) {
        self.onSelect = onSelect
    }

    private var currentTheme: QuranTheme {
        themeManager.currentTheme
    }

    private let suggestions: [(title: String, query: String)] = [
        ("Ayat Al-Kursi", "الله لا اله الا هو الحي القيوم"),
        ("Al-Fatihah", "الحمد لله رب العالمين"),
        ("Ar-Rahman", "الرحمن علم القران"),
        ("Al-Mulk", "تبارك الذي بيده الملك"),
        ("Al-Ikhlas", "قل هو الله احد"),
        ("Al-Kahf", "الحمد لله الذي انزل على عبده الكتاب"),
        ("Al-Waqi'ah", "اذا وقعت الواقعه"),
        ("An-Nas", "قل اعوذ برب الناس")
    ]

    public var body: some View {
        NavigationStack {
            ZStack {
                currentTheme.backgroundColor.ignoresSafeArea()
                currentTheme.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(BayanTheme.gold)

                        TextField("Type Ayah words in Arabic or English...", text: $searchText)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        if isSearching {
                            ProgressView()
                                .tint(BayanTheme.gold)
                                .scaleEffect(0.7)
                        } else if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                results = []
                                searchTask?.cancel()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(BayanTheme.gold.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    // Suggestion Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestions, id: \.title) { item in
                                Button {
                                    searchText = item.query
                                    #if os(iOS)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    #endif
                                    executeSearch(query: item.query, immediate: true)
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 10))
                                        Text(item.title)
                                            .font(.caption.weight(.medium))
                                    }
                                    .foregroundColor(BayanTheme.goldSoft)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(BayanTheme.gold.opacity(0.12))
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(BayanTheme.gold.opacity(0.25), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                    }

                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.top, 6)

                    // Results or Instructions List
                    if isSearching && results.isEmpty {
                        VStack(spacing: 14) {
                            Spacer()
                            ProgressView()
                                .tint(BayanTheme.gold)
                                .scaleEffect(1.2)
                            Text("Searching verses...")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                        }
                    } else if results.isEmpty && !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "text.magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(BayanTheme.gold.opacity(0.6))

                            Text("No verses matched '\(searchText)'")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("Try typing fewer words or key phrases like 'الرحمن' or 'رب العالمين'")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            Spacer()
                        }
                    } else if results.isEmpty {
                        VStack(spacing: 14) {
                            Spacer()
                            Image(systemName: "character.book.closed.fill")
                                .font(.system(size: 44))
                                .foregroundColor(BayanTheme.gold.opacity(0.7))

                            Text("Search Any Quran Verse")
                                .font(.title3.weight(.bold))
                                .foregroundColor(.white)

                            Text("Type any remembered word or phrase from the recitation, in Arabic or English translation, to identify the exact Surah and Ayah.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.65))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)

                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(results, id: \.id) { verse in
                                let surah = QuranDataService.shared.surah(for: verse.surahId) ?? Surah.sampleFatihah
                                Button {
                                    let recResult = RecognitionResult(
                                        surah: surah,
                                        startAyah: verse.ayahNumber,
                                        endAyah: min(surah.totalAyahs, verse.ayahNumber + 2),
                                        reciter: Reciter.unknownReciter,
                                        arabicSnippet: verse.arabicText,
                                        translationSnippet: verse.translationText,
                                        confidence: 1.0
                                    )
                                    QuranSyncManager.shared.addRecognition(recResult)
                                    #if os(iOS)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    #endif
                                    onSelect(recResult)
                                    dismiss()
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("\(surah.nameEnglish) • Ayah \(verse.ayahNumber)")
                                                .font(.caption.weight(.bold))
                                                .foregroundColor(BayanTheme.goldSoft)

                                            Spacer()

                                            Text(surah.nameArabic)
                                                .font(.caption.weight(.bold))
                                                .foregroundColor(BayanTheme.gold)
                                        }

                                        Text(verse.arabicText)
                                            .font(.system(size: 19, weight: .regular))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.trailing)
                                            .lineSpacing(4)
                                            .frame(maxWidth: .infinity, alignment: .trailing)

                                        if !verse.translationText.isEmpty {
                                            Text(verse.translationText)
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.7))
                                                .lineLimit(2)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                                .listRowBackground(Color.white.opacity(0.05))
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .scrollDismissesKeyboard(.immediately)
                    }
                }
            }
            .navigationTitle("Search Quran Verse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(BayanTheme.gold)
                }
            }
            .onChange(of: searchText) { _, newValue in
                executeSearch(query: newValue, immediate: false)
            }
            .onDisappear {
                searchTask?.cancel()
            }
        }
    }

    // MARK: - Debounced Asynchronous Background Search
    // Runs on background priority thread to ensure the UIKit keyboard remains 100% fluid and never hangs
    private func executeSearch(query: String, immediate: Bool) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= 2 else {
            results = []
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task {
            if !immediate {
                // 150ms debounce allows rapid typing without unnecessary work
                try? await Task.sleep(nanoseconds: 150_000_000)
            }
            if Task.isCancelled { return }

            let matches = await Task.detached(priority: .userInitiated) {
                return QuranVerseText.searchAllVerses(query: trimmed, limit: 50)
            }.value

            if !Task.isCancelled {
                withAnimation(.easeOut(duration: 0.15)) {
                    self.results = matches
                    self.isSearching = false
                }
            }
        }
    }
}
